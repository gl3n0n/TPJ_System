-- Create table
create table INV_BORROWING_HDR
(
  TRAN_NO                   VARCHAR2(16) not null,
  TRAN_DATE                 DATE not null,
  VESS_CODE_SRC             VARCHAR2(16),
  VESS_CODE_DES             VARCHAR2(16),
  TRAN_TYPE                 VARCHAR2(12) default 'BORROW' not null,
  STATUS                    VARCHAR2(12) default 'FOR APPROVAL' not null,
  REQUESTED_BY              VARCHAR2(16),
  PREPARED_BY               VARCHAR2(16),
  DT_PREPARED               DATE,
  APPROVED_BY               VARCHAR2(16),
  DT_APPROVED               DATE,
  REMARKS                   VARCHAR2(255),
  CREATED_BY                VARCHAR2(32) not null,
  DT_CREATED                DATE not null,
  MODIFIED_BY               VARCHAR2(32),
  DT_MODIFIED               DATE,
  OFC_CODE                  VARCHAR2(16) default 'HO'
);
-- Create/Recreate primary, unique and foreign key constraints 
alter table INV_BORROWING_HDR add constraint BOHD_PK primary key (TRAN_NO);
alter table INV_BORROWING_HDR add constraint BOHD_VESSELS foreign key (VESS_CODE) references INV_VESSELS (CODE);
alter table INV_BORROWING_HDR add constraint BOHD_APOF_FK foreign key (APPROVED_BY) references INV_APPROVING_OFFICER (CODE);
alter table INV_BORROWING_HDR add constraint BOHD_EMPL_REQUESTED_FK foreign key (REQUESTED_BY) references PMS_EMPLOYEES (EMPL_ID);
alter table INV_BORROWING_HDR add constraint BOHD_EMPL_PREPARED_FK foreign key (PREPARED_BY) references PMS_EMPLOYEES (EMPL_ID);
-- Create/Recreate indexes 
create index RSHD_DT_IDX on INV_BORROWING_HDR (DT_CREATED);

-- Create table
create table INV_BORROWING_DTL
(
  TRAN_NO                   VARCHAR2(16) not null,
  RSHD_RS_NO                VARCHAR2(16) not null,
  ITTY_CODE                 VARCHAR2(16) not null,
  CATE_CODE                 VARCHAR2(16) not null,
  ITGR_CODE                 VARCHAR2(16) not null,
  ITEM_CODE                 VARCHAR2(16) not null,
  QTY                       NUMBER(12,4) default 0 not null,
  APPROVED_QTY              NUMBER(12,4) default 0 not null,
  UOME_CODE                 VARCHAR2(16) not null,
  REMARKS                   VARCHAR2(128),
  CREATED_BY                VARCHAR2(32) not null,
  DT_CREATED                DATE not null,
  MODIFIED_BY               VARCHAR2(32),
  DT_MODIFIED               DATE
);
-- Create/Recreate primary, unique and foreign key constraints 
alter table INV_BORROWING_DTL add constraint BODT_PK primary key (TRAN_NO,CATE_CODE,ITTY_CODE,ITGR_CODE,ITEM_CODE);
alter table INV_BORROWING_DTL add constraint BODT_CSHD_FK foreign key (CSHD_CS_NO) references INV_CANVASS_HDR (CS_NO);
alter table INV_BORROWING_DTL add constraint BODT_POHD_FK foreign key (POHD_PO_NO) references INV_PO_HDR (PO_NO);
alter table INV_BORROWING_DTL add constraint BODT_RSHD_FK foreign key (RSHD_RS_NO) references INV_REQSLIP_HDR (RS_NO);
alter table INV_BORROWING_DTL add constraint BODT_UOME_FK foreign key (UOME_CODE) references INV_UNIT_OF_MEASURE (CODE);
