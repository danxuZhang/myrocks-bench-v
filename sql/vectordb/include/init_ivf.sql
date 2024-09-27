DROP TABLE IF EXISTS VECTORDB_DATA;
# create table to store trained faiss index for ivf
CREATE TABLE VECTORDB_DATA (
  id varchar(128) not null,
  type varchar(128) not null,
  seqno int not null,
  value JSON not null,
  primary key (id, type, seqno)
);
