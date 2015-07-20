alter table CMS_VOYAGE_ROUTE add (start_date date, end_date date);


prompt
prompt Creating table CMS_VOYAGE_PAX
prompt ==============================
prompt
create table CMS_VOYAGE_PAX
(
  VOYA_VESS_CODE   VARCHAR2(16) not null,
  VOYA_VOYAGE_DATE DATE not null,
  SEQ_NO           NUMBER(4) not null,
  EMPL_EMPL_ID     VARCHAR2(16),
  RANK_CODE        VARCHAR2(16),
  TITLE            VARCHAR2(32),
  DT_EMBARKED      DATE,
  DT_DISEMBARKED   DATE,
  BASIC_RATE       NUMBER(8,2) default 0 not null,
  BASIC_RATE_G     NUMBER(8,2) default 0 not null,
  APPROVED         VARCHAR2(1) default 'N' not null,
  CREATED_BY       VARCHAR2(32) not null,
  DT_CREATED       DATE not null,
  MODIFIED_BY      VARCHAR2(32),
  DT_MODIFIED      DATE
)
;

alter table CMS_VOYAGE_PAX
  add constraint VOPA_PK primary key (VOYA_VOYAGE_DATE,VOYA_VESS_CODE,SEQ_NO)
;

alter table CMS_VOYAGE_PAX
  add constraint VOPA_UK unique (VOYA_VOYAGE_DATE,VOYA_VESS_CODE,DT_EMBARKED)
;

--here hangs...

alter table CMS_VOYAGE_PAX
  add constraint VOPA_EMPL_FK foreign key (EMPL_EMPL_ID)
  references PMS_EMPLOYEES (EMPL_ID);

alter table CMS_VOYAGE_PAX
  add constraint VOPA_RANK_FK foreign key (RANK_CODE)
  references PMS_RANKS (CODE);

alter table CMS_VOYAGE_PAX
  add constraint VOPA_VOYA_FK foreign key (VOYA_VESS_CODE,VOYA_VOYAGE_DATE)
  references CMS_VOYAGES (VESS_CODE,VOYAGE_DATE);

create index VOPA_EMPL_FK_I on CMS_VOYAGE_CREW (EMPL_EMPL_ID)
;

create index VOPA_VOYA_FK_I on CMS_VOYAGE_PAX (VOYA_VOYAGE_DATE,VOYA_VESS_CODE)
;


alter table pys_payroll_dtl add adjusted varchar2(1) default 'N' not null;
