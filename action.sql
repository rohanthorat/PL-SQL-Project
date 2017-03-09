CREATE OR REPLACE PACKAGE project2_temp1
AS
        --Exception
	prerequisite_not_satisfied exception;
        bid_is_invalid exception;
        classid_is_invalid exception;
        class_is_full exception;
        student_is_already_registered exception;
        max_4_classes exception;
        stud_overload exception;
	not_registered exception; 						-- for que3
	no_student exception;							-- for que5
	student_not_found exception; 					-- for que7
	prerequisite_violation exception;					-- for que7
	student_id_invalid exception;					-- for que8

	--Reference cursors
	type ref_cursor_studDetails is ref cursor;			-- for que 3
	type ref_cursor_classDetails is ref cursor;			-- for que 5
	type ref_cursor_showStud is ref cursor;			-- for que2 
	type	ref_cursor_showCourses is ref cursor;			-- for que2 
	type	ref_cursor_showCourseCredits is ref cursor;	-- for que2 
	type	ref_cursor_showPrequisites is ref cursor;		-- for que2 
	type	ref_cursor_showClasses is ref cursor;			-- for que2 
	type	ref_cursor_showEnrollments is ref cursor;		-- for que2 
	type	ref_cursor_showGrades is ref cursor;			-- for que2 
	type	ref_cursor_showLogs is ref cursor;			-- for que2 

	--Procedures
	procedure studEnroll(v_id IN students.B#%TYPE, v_classid IN classes.classid%TYPE,v_out OUT VARCHAR2);		--que6
	procedure deleteEnroll(v_id IN students.B#%TYPE, v_classid IN classes.classid%TYPE,v_out OUT VARCHAR2);		--que7
	procedure delete_student(v_id IN students.B#%TYPE,v_out OUT VARCHAR2);								--qu8

	--Functions
	function getStudentDetails(v_stud_id IN enrollments.B#%TYPE)	--que3
	return ref_cursor_studDetails;
	
        function getClassDetails(v_classid IN classes.classid%TYPE)		--que5
        return ref_cursor_classDetails;
	
	function showStudents 										--que2
	return ref_cursor_showStud;
	
	function showCourses										--que2
	return ref_cursor_showCourses;

	function showCourseCredits									--que2
	return ref_cursor_showCourseCredits;

	function showPrerequisites									--que2
	return ref_cursor_showPrequisites;

	function showClasses										--que2
	return ref_cursor_showClasses;

	function showEnrollments									--que2
	return ref_cursor_showEnrollments;

	function showGrades										--que2
	return ref_cursor_showGrades;

	function showLogs											--que2
	return ref_cursor_showLogs;

END;
/

CREATE OR REPLACE PACKAGE BODY project2_temp1
AS

--question no 6
--This procedure is used to enroll a student to a particular class
procedure studEnroll(v_id IN students.B#%TYPE, v_classid IN classes.classid%TYPE, v_out OUT VARCHAR2)
is
        cursor c1 is SELECT *
   	                    FROM Students
                            WHERE B# = v_id;
        r1 c1%ROWTYPE;

        cursor c2 is
                SELECT *
                FROM Classes
                WHERE classid= v_classid ;
        r2 c2%ROWTYPE;

        cursor c3 is
                SELECT *
                FROM Enrollments
                WHERE B#= v_id
                AND classid=v_classid;
        r3 c3%ROWTYPE;

        cursor c4 is
                SELECT e.B#, e.classid, c.year, c.semester
                FROM Enrollments e, Classes c
                WHERE e.B#=v_id
                AND e.classid = c.classid;
        r4 c4%ROWTYPE;

        cursor c5 is
                        Select p.pre_dept_code, p.pre_course#, p.dept_code, p.course#
                        FROM Prerequisites p, Classes c
                        WHERE c.classid = v_classid
                        AND c.dept_code = p.dept_code
                        AND c.course# = p.course#;
        r5 c5%ROWTYPE;

        temp_counter number;
        temp_year Classes.year%TYPE;
        temp_sem Classes.semester%TYPE;
        temp_classid Classes.classid%TYPE;
        temp_lgrade Enrollments.lgrade%TYPE;



 BEGIN
        temp_counter := 0;
	temp := 0;
        open c1;
        open c2;
        open c3;
        open c4;
        open c5;
        fetch c1 into r1;
        fetch c2 into r2;
        fetch c3 into r3;
        fetch c4 into r4;
        fetch c5 into r5;
        if (c1%found) then
                if(c2%found) then
                         if (r2.class_size < r2.limit) then
                                if (c3%notfound) then

                                         -- logic to check for Number of Enrollments of students in same year and same semester
                                         SELECT Classes.year, Classes.semester, Classes.classid
                                        INTO temp_year, temp_sem, temp_classid
                                        FROM Classes
                                        WHERE classid=v_classid;


                                        while c4%found loop
                                                        if(r4.year = temp_year and r4.semester=temp_sem and r4.classid<>temp_classid) then
                                                                temp_counter := temp_counter + 1;
                                                        end if;
                                                        fetch c4 into r4;
                                        end loop;

                                        if (temp_counter<3) then
                                                        DBMS_OUTPUT.put_line('Go ahead with Student Enrollment');

                                                        --logic to check minimum prerequisite grade requirement
                                                       if (c5%found) then
                                                                while c5%found loop
                                                                        DBMS_OUTPUT.put_line('dept_code'||' '||'course#'||' '||'pre_dept_code'||' '||'pre_course#');
                                                                        DBMS_OUTPUT.put_line(r5.dept_code||' '||r5.course#||' '||r5.pre_dept_code||' '||r5.pre_course#);

                                                                       -- Logic to check whether student has taken the prerequisite or not 
									select count(*) into temp from Enrollments e, Classes c where
                                                                                     e.B# = v_id and
                                                                                     c.dept_code = r5.pre_dept_code and
                                                                                     c.course# = r5.pre_course# and
                                                                                     e.classid = c.classid;

									if (temp>0) then
										--means student has taken prerequisites, now check for prerequisites grades
											for g in (select lgrade into temp_lgrade from Enrollments e, Classes c where
                                                                        	        	     e.B# = v_id and
                                                                        	        	     c.dept_code = r5.pre_dept_code and
                                                                        	        	     c.course# = r5.pre_course# and
                                                                        	        	     e.classid = c.classid)
                                                                        		loop
                                                                        		        temp_lgrade:=g.lgrade;
                                                                        		        DBMS_OUTPUT.put_line(temp_lgrade);
                                                                        		        if(temp_lgrade<>'A' or temp_lgrade<>'B' or temp_lgrade<>'C') then
                                                                        	        	        raise prerequisite_not_satisfied;
                                                                        	        	else
                                                                        	        	        INSERT INTO Enrollments(B#, classid, lgrade)
                                                                        	        	        VALUES (v_id , v_classid, NULL);
                                                                        	        	        DBMS_OUTPUT.put_line('Student Enrolled Successfully');
													v_out := 'Student Enrolled Successfully';
                                                                 		        	end if;
                                                                         		end loop;
									else
											raise prerequisite_not_satisfied;
									end if;	
                                                                   	fetch c5 into r5;
                                                                 end loop;
                                                        else
                                                                INSERT INTO Enrollments(B#, classid, lgrade)
                                                                VALUES (v_id , v_classid, NULL);
                                                                DBMS_OUTPUT.put_line('Student Enrolled Successfully');
								v_out := 'Student Enrolled Successfully';
                                                        end if;


                                        elsif (temp_counter=3) then
                                                       DBMS_OUTPUT.put_line('You are over loaded');
							v_out:='You are over loaded';

                                                        --logic to check minimum prerequisite grade requirement
                                                        if (c5%found) then
                                                                while c5%found loop
                                                                        DBMS_OUTPUT.put_line('dept_code'||' '||'course#'||' '||'pre_dept_code'||' '||'pre_course#');
                                                                        DBMS_OUTPUT.put_line(r5.dept_code||' '||r5.course#||' '||r5.pre_dept_code||' '||r5.pre_course#);
 									
									-- Logic to check whether student has taken the prerequisite or not 
									select count(*) into temp from Enrollments e, Classes c where
                                                                                     e.B# = v_id and
                                                                                     c.dept_code = r5.pre_dept_code and
                                                                                     c.course# = r5.pre_course# and
                                                                                     e.classid = c.classid;

										if (temp>0) then
											--means student has taken prerequisites, now check for prerequisites grades
											for g in (select lgrade into temp_lgrade from Enrollments e, Classes c where
                                                                        	        	     e.B# = v_id and
                                                                        	        	     c.dept_code = r5.pre_dept_code and
                                                                        	        	     c.course# = r5.pre_course# and
                                                                        	        	     e.classid = c.classid)
                                                                        		loop
                                                                        		        temp_lgrade:=g.lgrade;
                                                                        		        DBMS_OUTPUT.put_line(temp_lgrade);
                                                                        		        if(temp_lgrade<>'A' or temp_lgrade<>'B' or temp_lgrade<>'C') then
                                                                        	        	        raise prerequisite_not_satisfied;
                                                                        	        	else
                                                                        	        	        INSERT INTO Enrollments(B#, classid, lgrade)
                                                                        	        	        VALUES (v_id , v_classid, NULL);
                                                                        	        	        DBMS_OUTPUT.put_line('Student Enrolled Successfully');
													v_out := 'Student Enrolled Successfully';
                                                                 		        	end if;
                                                                         		end loop;
										else
											raise prerequisite_not_satisfied;
										end if;	
			
                                                                        	fetch c5 into r5;
									end loop;
                                                        else
                                                                INSERT INTO Enrollments(B#, classid, lgrade)
                                                                VALUES (v_id , v_classid, NULL);
                                                                DBMS_OUTPUT.put_line('Student Enrolled Successfully');
								v_out := 'Student Enrolled Successfully';
                                                        end if;

                                            else
                                                        raise max_4_classes;
                                            end if;
                                else
                                        raise student_is_already_registered;
                                end if;
                          else
                                raise class_is_full;
                          end if;
                 else
                        raise classid_is_invalid;
                 end if;
         else
                raise bid_is_invalid;
         end if;

         close c5;
         close c4;
         close c3;
         close c2;
         close c1;

        EXCEPTION
                WHEN prerequisite_not_satisfied THEN
                        raise_application_error(3004,'Prerequisites not satisfied');
			--DBMS_OUTPUT.put_line('Prerequisites not satisfied');
			v_out := 'Prerequisites not satisfied';
                WHEN bid_is_invalid THEN
                        raise_application_error(3000,'The B# is invalid');
			--DBMS_OUTPUT.put_line('The B# is invalid');
			v_out := 'The B# is invalid';
                WHEN classid_is_invalid THEN
                        raise_application_error(3003,'The classid is invalid');
			--DBMS_OUTPUT.put_line('The classid is invalid');
			v_out := 'The classid is invalid';
                WHEN class_is_full THEN
			raise_application_error(3005,'The class is full');
                        --DBMS_OUTPUT.put_line('The class is full');
			v_out := 'The class is full';
                WHEN student_is_already_registered THEN
                        raise_application_error(3006,'The student is already in the class');
			--DBMS_OUTPUT.put_line('The student is already in the class');
			v_out := 'The student is already in the class';
                WHEN max_4_classes THEN
                        raise_application_error(3007,'Students cannot be enrolled in more than four classes in the same semester');
			--DBMS_OUTPUT.put_line('Students cannot be enrolled in more than four classes in the same semester');
			v_out := 'Students cannot be enrolled in more than four classes in the same semester';
                WHEN stud_overload THEN
                        raise_application_error(3008,'You are over loaded');
			--DBMS_OUTPUT.put_line('You are over loaded');
			v_out := 'You are over loaded';



END; --End of studEnroll procedure



--question no 7 delete student enrollment
--This procedure deletes the enrollment table entry of the respective student
procedure deleteEnroll(v_id IN students.B#%TYPE, v_classid IN classes.classid%TYPE,v_out OUT VARCHAR2)
IS
        cursor c1 is SELECT *
                            FROM Students
                            WHERE B# = v_id;
        r1 c1%ROWTYPE;

        cursor c2 is
                SELECT *
                FROM Classes
                WHERE classid= v_classid ;
        r2 c2%ROWTYPE;

        cursor c3 is
                SELECT *
                FROM Enrollments
                WHERE B#= v_id
                AND classid=v_classid;
        r3 c3%ROWTYPE;

        temp_counter number;
        temp_dept_code Classes.dept_code%TYPE;
        temp_course# Classes.course#%TYPE;


        prerequisite_violation exception;
        bid_is_invalid exception;
        classid_is_invalid exception;
        student_not_found exception;



 BEGIN
        temp_counter := 0;
        open c1;
        open c2;
        open c3;

        fetch c1 into r1;
        fetch c2 into r2;
        fetch c3 into r3;

        if (c1%found) then
                if(c2%found) then
                        if (c3%notfound) then
                                        raise student_not_found;
                        else
                                        SELECT dept_code, course# INTO temp_dept_code, temp_course#
                                        FROM Classes
                                        WHERE classid=v_classid;

                                        SELECT count(*) INTO temp_counter
                                        FROM Enrollments
                                        WHERE B#=v_id
                                        AND classid IN
                                                                (Select c.classid from Classes c, Prerequisites p
                                                                  WHERE c.dept_code=p.dept_code
                                                                  AND c.course#=p.course#
                                                                  AND pre_dept_code=temp_dept_code
                                                                  AND pre_course#=temp_course#);


                                        if temp_counter > 0 then
                                                raise prerequisite_violation;
                                        else

                                                DELETE FROM Enrollments
                                                WHERE B# = v_id and classid = v_classid;
						v_out:='Student successfully deleted from enrollments';

                                                select count(*) into temp_counter from Enrollments where B# = v_id;
                                                if temp_counter = 0 then
                                                        dbms_output.put_line('The student is not enrolled in any classes');
							v_out:='The student is not enrolled in any classes';
                                                end if;
                                                select count(*) into temp_counter from Enrollments where classid = v_classid;
                                                if temp_counter = 0 then
                                                        dbms_output.put_line('The class now has no students');
							v_out:='The class now has no students';
                                                end if;

                                        end if;
                         end if;

                 else
                        raise classid_is_invalid;
                 end if;
         else
                raise bid_is_invalid;
         end if;

         close c3;
         close c2;
         close c1;

        EXCEPTION
                WHEN prerequisite_violation THEN
                        raise_application_error(3010,'The drop is not permitted because another class uses it as a prerequisite');
			--DBMS_OUTPUT.put_line('The drop is not permitted because another class uses it as a prerequisite');
			v_out:='The drop is not permitted because another class uses it as a prerequisite';
                WHEN bid_is_invalid THEN
                         raise_application_error(3000,'The B# is invalid');
			--DBMS_OUTPUT.put_line('The B# is invalid');
			v_out:='The B# is invalid';
                WHEN classid_is_invalid THEN
                        raise_application_error(3003,'The classid is invalid');
			--DBMS_OUTPUT.put_line('The classid is invalid');
			v_out:='The classid is invalid';
                WHEN student_not_found THEN
			raise_application_error(3009,'The student is not enrolled in the class.');
                        DBMS_OUTPUT.put_line('The student is not enrolled in the class.');
			v_out:='The student is not enrolled in the class';


END; -- End pf Procedure deleteEnroll

--question no 8
--This procedure deletes the student entry from the student table
procedure delete_student(v_id IN students.B#%TYPE,v_out OUT VARCHAR2)
IS
        cursor c1 is SELECT *
                            FROM Students
                            WHERE B# = v_id;
        r1 c1%ROWTYPE;

 BEGIN
        open c1;
        fetch c1 into r1;

        if (c1%found) then
                DELETE FROM Students where B# = v_id;
		v_out:='Student successfully deleted from students';
         else
               raise student_id_invalid;
         end if;

         close c1;

        EXCEPTION
                WHEN student_id_invalid THEN
                      raise_application_error(3000,'The B# is invalid');
			--DBMS_OUTPUT.put_line('The B# is invalid');
			v_out:='The B# is invalid';

END;	--End of procedure delete_student

--question no 3
--This function displays student details
function getStudentDetails(v_stud_id IN enrollments.B#%TYPE)
return ref_cursor_studDetails
is
rc3 ref_cursor_studDetails;

        cursor c_id is
                SELECT *
                FROM students
                WHERE B#= v_stud_id;
        r_id c_id%ROWTYPE;

        cursor c_e is
                SELECT *
                FROM Enrollments
                WHERE B# = v_stud_id;
        r_e c_e%ROWTYPE;


 BEGIN
        open c_id;
        fetch c_id into r_id;
        if(c_id%found) then
                open c_e;
                fetch c_e into r_e;
                if(c_e%found) then
                         	open rc3 for
						 SELECT c.classid, c.dept_code, c.course#, c.sect#, c.year, c.semester, e.lgrade, g.ngrade
                             			 FROM Classes c, Enrollments e, Grades g
                             			 WHERE e.B# = v_stud_id
                          			    AND ( e.classid = c.classid AND e.lgrade = g.lgrade);
				return rc3;
				close rc3;
                         close c_e;
                else
                        raise not_registered;
                        close c_e;
                end if;
                close c_id;
        else
                raise bid_is_invalid;
                close c_id;
        end if;
	
	Exception
		WHEN bid_is_invalid THEN
			raise_application_error(3000,'The B# is invalid');
                        --dbms_output.put_line('The B# is invalid');
		WHEN not_registered THEN
			raise_application_error(3001,'The student has not taken any course');
                        --dbms_output.put_line('The student has not taken any course');

 END; -- End of function getStudentDetails


--question no 5
--This function displays class details
function getClassDetails(v_classid IN classes.classid%TYPE)
return ref_cursor_classDetails
is
rc5 ref_cursor_classDetails;

        cursor c_id is
                SELECT *
                FROM Classes
                WHERE classid= v_classid;
        r_id c_id%ROWTYPE;

        cursor c_e is
                SELECT *
                FROM Enrollments
                WHERE classid = v_classid;
        r_e c_e%ROWTYPE;


 BEGIN
        open c_id;
        fetch c_id into r_id;
        if (c_id%found) then
                open c_e;
                fetch c_e into r_e;
                if(c_e%found) then
                         open rc5 for SELECT c.classid, c1.title, s.B#, s.firstname
                           					FROM Classes c, Courses c1, Students s
                           					WHERE c.classid = v_classid
                         				        AND c.dept_code = c1.dept_code
                       					        AND c.course# = c1.course#
                       						AND s.B# IN
                                                				(SELECT B#
                                                 				 FROM Enrollments
                                                				 WHERE classid = v_classid);
                         return rc5;
			 close rc5;
                         close c_e;
                else
                        raise no_student;
                        close c_e;
                end if;
                close c_id;
                close c_id;
        else
                raise classid_is_invalid;
                close c_id;
        end if;

	Exception
		WHEN classid_is_invalid THEN
			raise_application_error(3003,'The classid is invalid');
                        DBMS_OUTPUT.put_line('The classid is invalid');
		WHEN no_student THEN
			raise_application_error(3004,'No Student has enrolled in the class');
                        DBMS_OUTPUT.put_line('No Student has enrolled in the class');

 END; -- End of function getClassDetails

--question no 2 showStudents
--displays all details of all students
function showStudents 
return ref_cursor_showStud is
rc2_student ref_cursor_showStud;
BEGIN
 	  	open rc2_student for 
   	  		select * from Students;
   		return rc2_student;
  	 	close rc2_student;
END;	--End of function showStudents


--question no 2 showCourses
--display all course details
function showCourses
return ref_cursor_showCourses is
rc2_course ref_cursor_showCourses;
BEGIN
 	  	open rc2_course for 
   	  		select * from Courses;
   		return rc2_course;
  	 	close rc2_course;
END;	--End of function showCourses

--question no 2 showCourseCredits
--displays course credit details
function showCourseCredits
return ref_cursor_showCourseCredits is
rc2_courseCredit ref_cursor_showCourseCredits;
BEGIN
 	  	open rc2_courseCredit for 
   	  		select * from Course_Credit;
   		return rc2_courseCredit;
  	 	close rc2_courseCredit;
END;	--End of function showCourses

--question no 2 showPrerequisites
function showPrerequisites
return ref_cursor_showPrequisites is
rc2_prerequisites ref_cursor_showPrequisites;
BEGIN
 	  	open rc2_prerequisites for 
   	  		select * from Prerequisites;
   		return rc2_prerequisites;
  	 	close rc2_prerequisites;
END;	--End of function showPrerequisites


--question no 2 showClasses
--displays all class details
function showClasses
return ref_cursor_showClasses is
rc2_classes ref_cursor_showClasses;
BEGIN
 	  	open rc2_classes for 
   	  		select * from Classes;
   		return rc2_classes;
  	 	close rc2_classes;
END;	--End of function showClasses


--question no 2 showEnrollments
--displays all enrollments display
function showEnrollments
return ref_cursor_showEnrollments is
rc2_enrollments ref_cursor_showEnrollments;
BEGIN
 	  	open rc2_enrollments for 
   	  		select * from Enrollments;
   		return rc2_enrollments;
  	 	close rc2_enrollments;
END;	--End of function showEnrollments


--question no 2 showGrades
--display all grades details
function showGrades
return ref_cursor_showGrades is
rc2_grades ref_cursor_showGrades;
BEGIN
 	  	open rc2_grades for 
   	  		select * from Grades;
   		return rc2_grades;
  	 	close rc2_grades;
END;	--End of function showGrades


--question no 2 showLogs
--display all log details
function showLogs
return ref_cursor_showLogs is
rc2_logs ref_cursor_showLogs;
BEGIN
 	  	open rc2_logs for 
   	  		select * from Logs;
   		return rc2_logs;	
  	 	close rc2_logs;
END;	--End of function showLogs





END; --End of package
/
show error

