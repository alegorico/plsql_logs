CREATE OR REPLACE PACKAGE BODY &NOMBRE_PAQUETE AS

    -- Mapeo de número a nivel textual
    FUNCTION numero_a_nivel(p_numero IN NUMBER) RETURN VARCHAR2 IS
    BEGIN
        CASE p_numero
            WHEN 1 THEN RETURN 'DEBUG';
            WHEN 2 THEN RETURN 'INFO';
            WHEN 3 THEN RETURN 'WARN';
            WHEN 4 THEN RETURN 'ERROR';
            ELSE RETURN NULL;
        END CASE;
    END numero_a_nivel;

    -- Chequeo si el log debe ser silenciado, insensible a mayusculas/minusculas/espacios y semantica de nivel
    FUNCTION is_silenced(p_module_name VARCHAR2, p_insertion_type NUMBER) RETURN BOOLEAN IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count
        FROM &NOMBRE_TABLA_CFG
        WHERE module_name_upper = UPPER(TRIM(p_module_name))
          AND (insertion_type IS NULL OR p_insertion_type <= insertion_type);
        RETURN v_count > 0;
    EXCEPTION
        WHEN OTHERS THEN RETURN FALSE; -- Si no existe la tabla, no silenciar
    END is_silenced;

    FUNCTION get_ancestor_execution RETURN VARCHAR2 IS
        v_module_name VARCHAR2(100);
        v_action_name VARCHAR2(100);
    BEGIN
        DBMS_APPLICATION_INFO.READ_MODULE(v_module_name, v_action_name);
        RETURN v_action_name;
    END;

    FUNCTION get_parent_execution_id RETURN VARCHAR2 IS
        v_parent_id VARCHAR2(100);
    BEGIN
        DBMS_APPLICATION_INFO.READ_CLIENT_INFO(v_parent_id);
        RETURN v_parent_id;
    END;

    FUNCTION start_execution(p_module_name VARCHAR2, p_ancestor_execution_id VARCHAR2 DEFAULT NULL) RETURN VARCHAR2 IS
        v_execution_id VARCHAR2(32);
        v_ancestor_execution_id VARCHAR2(100);
        v_module_name VARCHAR2(100);
        v_action_name VARCHAR2(100);
    BEGIN
        DBMS_APPLICATION_INFO.SET_MODULE(p_module_name, '');
        DBMS_APPLICATION_INFO.READ_CLIENT_INFO(v_execution_id);

        IF v_execution_id IS NULL OR v_execution_id = '' THEN
            v_execution_id := LOWER(RAWTOHEX(SYS_GUID()));
            DBMS_APPLICATION_INFO.SET_CLIENT_INFO(v_execution_id);
        END IF;

        -- Si no se pasa ancestor, intenta recuperarlo del contexto
        IF p_ancestor_execution_id IS NOT NULL THEN
            DBMS_APPLICATION_INFO.SET_ACTION(p_ancestor_execution_id);
            v_ancestor_execution_id := p_ancestor_execution_id;
        ELSE
            v_ancestor_execution_id := get_parent_execution_id;
            -- Si existe y es distinto del actual, lo usamos como ancestor
            IF v_ancestor_execution_id IS NOT NULL AND v_ancestor_execution_id <> v_execution_id THEN
                DBMS_APPLICATION_INFO.SET_ACTION(v_ancestor_execution_id);
            ELSE
                DBMS_APPLICATION_INFO.SET_ACTION('');
                v_ancestor_execution_id := NULL;
            END IF;
        END IF;

        -- Trazabilidad: registrar inicio
        log_info('Start execution for module: ' || p_module_name);

        RETURN v_execution_id;
    END;

    PROCEDURE end_execution IS
        v_execution_id VARCHAR2(32);
        v_module_name  VARCHAR2(100);
    BEGIN
        DBMS_APPLICATION_INFO.READ_MODULE(v_module_name, v_execution_id);

        -- Trazabilidad: registrar fin
        log_info('End execution for module: ' || v_module_name);

        DBMS_APPLICATION_INFO.SET_CLIENT_INFO('');
        DBMS_APPLICATION_INFO.SET_ACTION('');
        DBMS_APPLICATION_INFO.SET_MODULE('', '');
    END;

    -- Chequeo si el modulo tiene cola habilitada
    FUNCTION is_queue_enabled(p_module_name VARCHAR2) RETURN BOOLEAN IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count
        FROM &NOMBRE_TABLA_QUEUE_CFG
        WHERE module_name_upper = UPPER(TRIM(p_module_name))
        AND queue_enabled = 1;
        RETURN v_count > 0;
    END is_queue_enabled;

    -- Procedimiento centralizado de inserción a cola
    PROCEDURE insert_log_to_queue(
        p_execution_id          VARCHAR2,
        p_ancestor_execution_id VARCHAR2,
        p_session_id            VARCHAR2,
        p_user_name             VARCHAR2,
        p_module_name           VARCHAR2,
        p_log_timestamp         TIMESTAMP DEFAULT SYSTIMESTAMP,
        p_insertion_type        NUMBER,
        p_log_message           VARCHAR2 DEFAULT NULL,
        p_error_code            VARCHAR2 DEFAULT NULL,
        p_error_message         VARCHAR2 DEFAULT NULL
    ) IS
        v_insertion_type_txt VARCHAR2(20);
        v_message SYS.AQ$_JMS_TEXT_MESSAGE;
        v_json CLOB;
        v_enqueue_options DBMS_AQ.ENQUEUE_OPTIONS_T;
        v_message_props DBMS_AQ.MESSAGE_PROPERTIES_T;
        v_msgid RAW(16);
    PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        v_insertion_type_txt := numero_a_nivel(p_insertion_type);

        -- Crear mensaje JSON
        v_json := '{' ||
            '"timestamp":"' || TO_CHAR(p_log_timestamp, 'YYYY-MM-DD"T"HH24:MI:SS.FF3"Z"') || '",' ||
            '"execution_id":"' || p_execution_id || '",' ||
            '"ancestor_execution_id":"' || p_ancestor_execution_id || '",' ||
            '"session_id":"' || p_session_id || '",' ||
            '"user_name":"' || p_user_name || '",' ||
            '"module_name":"' || p_module_name || '",' ||
            '"level":"' || v_insertion_type_txt || '",' ||
            '"message":"' || REPLACE(p_log_message, '"', '\"') || '",' ||
            '"error_code":"' || p_error_code || '",' ||
            '"error_message":"' || REPLACE(p_error_message, '"', '\"') || '"' ||
        '}';

        -- Crear mensaje JMS
        v_message := SYS.AQ$_JMS_TEXT_MESSAGE.construct;
        v_message.set_text(v_json);

        -- Configurar propiedades del mensaje
        v_message_props.priority := p_insertion_type;
        v_message_props.correlation := p_execution_id;

        -- Enviar a cola
        DBMS_AQ.ENQUEUE(
            queue_name         => '&NOMBRE_COLA_JMS',
            enqueue_options    => v_enqueue_options,
            message_properties => v_message_props,
            payload            => v_message,
            msgid              => v_msgid
        );

        COMMIT;
    END insert_log_to_queue;

    -- Procedimiento principal de inserción
    PROCEDURE insert_log(
        p_execution_id          VARCHAR2,
        p_ancestor_execution_id VARCHAR2,
        p_session_id            VARCHAR2,
        p_user_name             VARCHAR2,
        p_module_name           VARCHAR2,
        p_log_timestamp         TIMESTAMP DEFAULT SYSTIMESTAMP,
        p_insertion_type        NUMBER,
        p_log_message           VARCHAR2 DEFAULT NULL,
        p_error_code            VARCHAR2 DEFAULT NULL,
        p_error_message         VARCHAR2 DEFAULT NULL
    ) IS
    BEGIN
        -- Solo enviar a cola si NO esta silenciado Y la cola esta habilitada para el modulo
        IF NOT is_silenced(p_module_name, p_insertion_type) AND is_queue_enabled(p_module_name) THEN
            insert_log_to_queue(
                p_execution_id, p_ancestor_execution_id, p_session_id,
                p_user_name, p_module_name, p_log_timestamp,
                p_insertion_type, p_log_message, p_error_code, p_error_message
            );
        END IF;
    END insert_log;

    PROCEDURE log_debug(p_log_message VARCHAR2) IS
        v_execution_id VARCHAR2(32);
        v_module_name  VARCHAR2(100);
        v_action_name  VARCHAR2(100);
        v_ancestor_execution_id VARCHAR2(100);
    BEGIN
        DBMS_APPLICATION_INFO.READ_CLIENT_INFO(v_execution_id);
        DBMS_APPLICATION_INFO.READ_MODULE(v_module_name, v_action_name);
        v_ancestor_execution_id := v_action_name;

        insert_log(
            p_execution_id          => v_execution_id,
            p_ancestor_execution_id => v_ancestor_execution_id,
            p_session_id            => SYS_CONTEXT('USERENV','SESSIONID'),
            p_user_name             => USER,
            p_module_name           => v_module_name,
            p_insertion_type        => 1, -- DEBUG
            p_log_message           => p_log_message
        );
    END;

    PROCEDURE log_info(p_log_message VARCHAR2) IS
        v_execution_id VARCHAR2(32);
        v_module_name  VARCHAR2(100);
        v_action_name  VARCHAR2(100);
        v_ancestor_execution_id VARCHAR2(100);
    BEGIN
        DBMS_APPLICATION_INFO.READ_CLIENT_INFO(v_execution_id);
        DBMS_APPLICATION_INFO.READ_MODULE(v_module_name, v_action_name);
        v_ancestor_execution_id := v_action_name;

        insert_log(
            p_execution_id          => v_execution_id,
            p_ancestor_execution_id => v_ancestor_execution_id,
            p_session_id            => SYS_CONTEXT('USERENV','SESSIONID'),
            p_user_name             => USER,
            p_module_name           => v_module_name,
            p_insertion_type        => 2, -- INFO
            p_log_message           => p_log_message
        );
    END;

    PROCEDURE log_warn(p_log_message VARCHAR2) IS
        v_execution_id VARCHAR2(32);
        v_module_name  VARCHAR2(100);
        v_action_name  VARCHAR2(100);
        v_ancestor_execution_id VARCHAR2(100);
    BEGIN
        DBMS_APPLICATION_INFO.READ_CLIENT_INFO(v_execution_id);
        DBMS_APPLICATION_INFO.READ_MODULE(v_module_name, v_action_name);
        v_ancestor_execution_id := v_action_name;

        insert_log(
            p_execution_id          => v_execution_id,
            p_ancestor_execution_id => v_ancestor_execution_id,
            p_session_id            => SYS_CONTEXT('USERENV','SESSIONID'),
            p_user_name             => USER,
            p_module_name           => v_module_name,
            p_insertion_type        => 3, -- WARN
            p_log_message           => p_log_message
        );
    END;

    PROCEDURE log_error(p_error_code VARCHAR2, p_error_message VARCHAR2) IS
        v_execution_id VARCHAR2(32);
        v_module_name  VARCHAR2(100);
        v_action_name  VARCHAR2(100);
        v_ancestor_execution_id VARCHAR2(100);
    BEGIN
        DBMS_APPLICATION_INFO.READ_CLIENT_INFO(v_execution_id);
        DBMS_APPLICATION_INFO.READ_MODULE(v_module_name, v_action_name);
        v_ancestor_execution_id := v_action_name;

        insert_log(
            p_execution_id          => v_execution_id,
            p_ancestor_execution_id => v_ancestor_execution_id,
            p_session_id            => SYS_CONTEXT('USERENV','SESSIONID'),
            p_user_name             => USER,
            p_module_name           => v_module_name,
            p_insertion_type        => 4, -- ERROR
            p_error_code            => p_error_code,
            p_error_message         => p_error_message
        );
    END;

END;
/