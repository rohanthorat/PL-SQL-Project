--Sequence for generating log id's
CREATE SEQUENCE project2_logid
START WITH 1000
INCREMENT BY 1;
/

--Trigger for log record once record is inserted in Students table
CREATE OR REPLACE TRIGGER studInsert
AFTER INSERT ON Students
FOR EACH ROW
BEGIN
                INSERT into logs
                VALUES(project2_logid.NEXTVAL,(Select user from dual),SYSDATE,'Students','INSERT',:new.B#);
END;
/
show error

--Trigger for log record once record is deleted from Students table
CREATE OR REPLACE TRIGGER studDelete
AFTER DELETE ON Students
FOR EACH ROW
BEGIN
                INSERT into logs
                VALUES(project2_logid.NEXTVAL,(Select user from dual),SYSDATE,'Students','INSERT',:old.B#);
END;
/
show error

--Trigger for log record once record is inserted in Enrollments table
CREATE OR REPLACE TRIGGER enrollInsert
AFTER INSERT ON Enrollments
FOR EACH ROW
BEGIN
                INSERT into logs
                VALUES(project2_logid.NEXTVAL,(Select user from dual),SYSDATE,'Students','INSERT',:new.B#||','||:new.classid);
END;
/
show error

--Trigger for log record once record is deleted from Enrollments table
CREATE OR REPLACE TRIGGER enrollDelete
AFTER DELETE ON Enrollments
FOR EACH ROW
BEGIN
                INSERT into logs
                VALUES(project2_logid.NEXTVAL,(Select user from dual),SYSDATE,'Students','INSERT',:old.B#||','||:old.classid);
END;
/
show error

CREATE OR REPLACE TRIGGER delete_student_from_enroll
BEFORE DELETE ON students
FOR EACH ROW
BEGIN
   delete from enrollments where B# = :old.B#;
END;
/
show error

CREATE OR REPLACE TRIGGER stud_enroll
AFTER INSERT ON Enrollments
FOR EACH ROW
BEGIN
	 update Classes set class_size=class_size+1
   	 where classid = :new.classid;
END;
/
show error

CREATE OR REPLACE TRIGGER deleteEnroll
AFTER DELETE ON Enrollments
FOR EACH ROW
BEGIN
   update Classes set class_size=class_size-1
   where classid = :old.classid;  
 END
/
show error
