<%@ page import="java.sql.*" %>
<%
String[] ids = request.getParameterValues("studentIds");
if (ids == null || ids.length == 0) {
    response.sendRedirect("list_students.jsp?error=No students selected for deletion.");
    return;
}

Connection conn = null;
PreparedStatement pstmt = null;

try {
    Class.forName("com.mysql.cj.jdbc.Driver");
    conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/student_management", "root", "minhquantqd");
    StringBuilder sql = new StringBuilder("DELETE FROM students WHERE id IN (");
    for (int i = 0; i < ids.length; i++) {
        sql.append("?");
        if (i < ids.length - 1) sql.append(",");
    }
    sql.append(")");

    pstmt = conn.prepareStatement(sql.toString());
    for (int i = 0; i < ids.length; i++) {
        pstmt.setInt(i + 1, Integer.parseInt(ids[i]));
    }

    int deleted = pstmt.executeUpdate();
    response.sendRedirect("list_students.jsp?message=" + deleted + " students deleted successfully!");

} catch (Exception e) {
    e.printStackTrace();
    response.sendRedirect("list_students.jsp?error=Bulk delete failed: " + e.getMessage());
} finally {
    try { 
        if (pstmt != null) pstmt.close(); 
    } 
    catch (SQLException ex) {}
    try { 
        if (conn != null) conn.close(); 
    } 
    catch (SQLException ex) {}
}
%>
