import java.sql.*;
import java.util.Scanner;

import oracle.jdbc.OracleTypes;
import oracle.jdbc.pool.OracleDataSource;

public class MenuDriven {

	public static void main(String args[])
	{
		startup();
	}
	
	public static void startup()
	{
		System.out.println("\n\n--------------------------------------------");
		System.out.println("Welcome to Student Registration System");
		System.out.println("--------------------------------------------");
		System.out.println("1. View tables");
		System.out.println("2. Exit");
		Scanner sc = new Scanner(System.in);
		System.out.print("Enter  your choice: ");
		Integer in = Integer.parseInt(sc.nextLine());
		switch (in)
		{
			case 1:
				tablesMenu();
				break;
			case 2:
				break;
			default:
				System.out.println("Input not valid. Please try again.");
		}
		sc.close();
	}
	
	public static void tablesMenu()
	{
		System.out.println("\n\n--------------------------------------------");
		System.out.println("Tables");
		System.out.println("--------------------------------------------");
		System.out.println("1. Students");
		System.out.println("2. Enrollments");
		System.out.println("3. Back to previous menu");
		Scanner sc = new Scanner(System.in);
		System.out.print("Enter your choice: ");
		Integer in = Integer.parseInt(sc.nextLine());
		switch (in)
		{
			case 1:
				displayStudents();
				break;
			case 2:
				
				break;
			case 3:
				startup();
				break;
			default:
				System.out.println("Input not valid. Please try again.");
		}
		sc.close();
	}
	
	public static void displayStudents()
	{
		 try
		    {
		        //Connecting to Oracle server
		        OracleDataSource ds = new OracleDataSource();
		        ds.setURL("jdbc:oracle:thin:@castor.cc.binghamton.edu:1521:acad111");
		        Connection conn = ds.getConnection("rthorat1", "th638281");

		        //Prepare to call stored procedure:
		        CallableStatement cs = conn.prepareCall("begin ? := project2_temp1.showStudents(); end;");
		        
			   //register the out parameter (the first parameter)
		        cs.registerOutParameter(1, OracleTypes.CURSOR);
		        
		        
		        // execute and retrieve the result set
		        cs.execute();
		        ResultSet rs = (ResultSet)cs.getObject(1);

		        // print the results
		        while (rs.next()) {
		            System.out.println(rs.getString(1) + "\t" +
		                rs.getString(2) + "\t" + rs.getString(3) + 
		                rs.getString(4) + 
		                "\t" + rs.getDouble(5) + "\t" +
		                rs.getString(6));
		        }

		        //close the result set, statement, and the connection
		        cs.close();
		        conn.close();
		   } 
		   catch (Exception ex) { System.out.println ("\n*** SQLException caught ***\n" + ex.getMessage());}
	}
}
