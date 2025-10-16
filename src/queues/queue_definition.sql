-- Eliminación idempotente de cola existente
BEGIN
    DBMS_AQADM.STOP_QUEUE(queue_name => '&NOMBRE_COLA_JMS');
    DBMS_AQADM.DROP_QUEUE(queue_name => '&NOMBRE_COLA_JMS');
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

-- Creación de la cola JMS
BEGIN
    DBMS_AQADM.CREATE_QUEUE(
        queue_name         => '&NOMBRE_COLA_JMS',
        queue_table        => '&QUEUE_TABLE_NAME',
        queue_type         => DBMS_AQADM.NORMAL_QUEUE,
        max_retries        => 3,
        retry_delay        => 60,
        retention_time     => 86400,
        dependency_tracking => FALSE,
        comment            => 'Queue for logging system messages'
    );
    
    DBMS_AQADM.START_QUEUE(queue_name => '&NOMBRE_COLA_JMS');
END;
/