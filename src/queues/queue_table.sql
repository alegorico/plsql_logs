-- Creación idempotente de la tabla de cola para AQ
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE &QUEUE_TABLE_NAME';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

CREATE TABLE &QUEUE_TABLE_NAME (
    q_name           VARCHAR2(128),
    msgid            RAW(16),
    corr_id          VARCHAR2(128),
    priority         NUMBER,
    state            NUMBER,
    delay            TIMESTAMP WITH TIME ZONE,
    expiration       TIMESTAMP WITH TIME ZONE,
    time_manager_info TIMESTAMP WITH TIME ZONE,
    local_order_no   NUMBER,
    chain_no         NUMBER,
    cscn             NUMBER,
    dscn             NUMBER,
    enq_time         TIMESTAMP WITH TIME ZONE,
    enq_uid          NUMBER,
    enq_tid          VARCHAR2(30),
    deq_time         TIMESTAMP WITH TIME ZONE,
    deq_uid          NUMBER,
    deq_tid          VARCHAR2(30),
    retry_count      NUMBER,
    exception_qschema VARCHAR2(30),
    exception_queue  VARCHAR2(30),
    step_no          NUMBER,
    recipient_key    NUMBER,
    dequeue_msgid    RAW(16),
    user_data        SYS.AQ$_JMS_TEXT_MESSAGE,
    user_prop        SYS.AQ$_JMS_USERPROPARRAY
);