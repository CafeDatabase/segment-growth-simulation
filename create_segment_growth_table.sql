  CREATE TABLE CAPACITY_SEGMENTS
   (    OWNER VARCHAR2(30),
        SEGMENT_NAME VARCHAR2(30),
        SEGMENT_TYPE VARCHAR2(30),
        PARTITION_NAME VARCHAR2(30),
		SEGMENT_SIZE NUMBER,
        CAPACITY_LAST_MONTH NUMBER,
        CURRENT_CAPACITY NUMBER,
        FUTURE_CAPACITY NUMBER,
        SEGMENT_PCT_OCCUPIED NUMBER,
        INSTANT_MEASURE DATE
   ) SEGMENT CREATION IMMEDIATE;
   