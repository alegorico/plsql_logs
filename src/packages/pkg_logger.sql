

-- Paquete de logging con chequeo de silenciamiento y trazabilidad de start/end execution
CREATE OR REPLACE PACKAGE &NOMBRE_PAQUETE AS
    FUNCTION start_execution(p_module_name VARCHAR2, p_ancestor_execution_id VARCHAR2 DEFAULT NULL) RETURN VARCHAR2;
    PROCEDURE end_execution;

    FUNCTION get_ancestor_execution RETURN VARCHAR2;
    FUNCTION get_parent_execution_id RETURN VARCHAR2;

    PROCEDURE log_debug(p_log_message VARCHAR2);
    PROCEDURE log_info(p_log_message VARCHAR2);
    PROCEDURE log_warn(p_log_message VARCHAR2);
    PROCEDURE log_error(p_error_code VARCHAR2, p_error_message VARCHAR2);
END;
/

CREATE OR REPLACE PACKAGE BODY &NOMBRE_PAQUETE AS

    -- Mapeo de numero a nivel textual
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
          AND (
                insertion_type IS NULL 
                OR p_insertion_type <= insertion_type
              );
        RETURN v_count > 0;
    END is_silenced;

    -- Procedimiento centralizado de insercion de logs
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
        v_insertion_type_txt VARCHAR2(20);
    PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        v_insertion_type_txt := numero_a_nivel(p_insertion_type);

        -- Solo insertamos el log si no esta silenciado
        IF NOT is_silenced(p_module_name, p_insertion_type) THEN
            INSERT INTO &NOMBRE_TABLA_LOG (
                execution_id, ancestor_execution_id, session_id, user_name, module_name,
                log_timestamp, insertion_type, log_message, error_code, error_message
            ) VALUES (
                p_execution_id,
                p_ancestor_execution_id,
                p_session_id,
                p_user_name,
                p_module_name,
                p_log_timestamp,
                v_insertion_type_txt,
                p_log_message,
                p_error_code,
                p_error_message
            );
            COMMIT;
        END IF;
    END insert_log;

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

