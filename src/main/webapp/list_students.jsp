<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Student List</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
            background-color: #f5f5f5;
        }
        h1 { color: #333; }
        .message {
            padding: 10px;
            margin-bottom: 20px;
            border-radius: 5px;
        }
        .success {
            background-color: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }
        .error {
            background-color: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
        }
        .btn {
            display: inline-block;
            padding: 10px 20px;
            margin-bottom: 20px;
            background-color: #007bff;
            color: white;
            text-decoration: none;
            border-radius: 5px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            background-color: white;
        }
        th {
            background-color: #007bff;
            color: white;
            padding: 12px;
            text-align: left;
        }
        td {
            padding: 10px;
            border-bottom: 1px solid #ddd;
        }
        tr:hover { background-color: #f8f9fa; }
        .action-link {
            color: #007bff;
            text-decoration: none;
            margin-right: 10px;
        }
        .delete-link { color: #dc3545; }
        
        .table-responsive {
         overflow-x: auto;
            }

        @media (max-width: 768px) {
    table {
        font-size: 12px;
    }
    th, td {
        padding: 5px;
    }
}
    </style>
</head>
<body>
    <h1>📚 Student Management System</h1>
    
    <% if (request.getParameter("message") != null) { %>
        <div class="message success">
           <i>☑️</i><%= request.getParameter("message") %>
        </div>
    <% } %>
    
    <% if (request.getParameter("error") != null) { %>
        <div class="message error">
            <i>❌</i><%= request.getParameter("error") %>
        </div>
    <% } %>
    
    <a href="add_student.jsp" class="btn">➕ Add New Student</a>
     <a href="export_csv.jsp" class="btn">➕ Export to CSV</a>
    
    
 <script>
setTimeout(function() {
    var messages = document.querySelectorAll('.message');
    messages.forEach(function(msg) {
        msg.style.display = 'none';
    });
}, 3000);
</script>

<%
    //Pagination & search setup
    int currentPage = 1;
    int totalPages = 1;
    int totalRecords = 0;
    int recordsPerPage = 10;
    String keyword = request.getParameter("keyword");
    String queryString = "";

    String pageParam = request.getParameter("page");
    try {
        if (pageParam != null && !pageParam.trim().isEmpty()) {
            currentPage = Integer.parseInt(pageParam);
            if (currentPage < 1) currentPage = 1;
        }
    } catch (NumberFormatException e) {
        currentPage = 1;
    }

    if (keyword != null && !keyword.trim().isEmpty()) {
        queryString = "&keyword=" + keyword;
    }

    int offset = (currentPage - 1) * recordsPerPage;
 	// Sorting setup
    String sortBy = request.getParameter("sort");
    String order = request.getParameter("order");
    if (sortBy == null || sortBy.trim().isEmpty()) sortBy = "id";
    if (order == null || order.trim().isEmpty()) order = "desc";
    String nextOrder = order.equals("asc") ? "desc" : "asc";

%>
                
    <form action="list_students.jsp" method="GET">
    <input type="text" name="keyword" placeholder="Search by name or code...">
    <button type="submit">Search</button>
    <a href="list_students.jsp">Clear</a>
    </form>
    <!--bulk delete-->
    <form action="bulk_delete.jsp" method="post" onsubmit="return confirmBulkDelete();">
    <button type="submit" class="btn">🗑️ Delete Selected</button>
   
    <div class="table-responsive">
    <table>
        <thead>
            <tr>
                <th><input type="checkbox" id="selectAll" onclick="toggleSelectAll(this)"></th>
                <th>ID</th>
                <th>Student Code</th>
                <th><a href="list_students.jsp?sort=full_name&order=<%= nextOrder %><%= queryString %>">Full Name</a></th>
                <th>Email</th>
                <th>Major</th>
                <th><a href="list_students.jsp?sort=created_at&order=<%= nextOrder %><%= queryString %>">Created At</a></th>
                <th>Actions</th>
            </tr>
        </thead>
        <tbody>
<%
    Connection conn = null;
    Statement stmt = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    PreparedStatement countStmt;
 
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        
        conn = DriverManager.getConnection(
            "jdbc:mysql://localhost:3306/student_management",
            "root",
            "minhquantqd"
        );
        // Pseudocode:
//tìm tên
    String countSql;    
//count total records
if (keyword != null && !keyword.isEmpty()) {
    countSql = "SELECT COUNT(*) FROM students WHERE full_name LIKE ? OR student_code LIKE ? OR major LIKE ?";
     countStmt = conn.prepareStatement(countSql);
        countStmt.setString(1, "%" + keyword + "%");
        countStmt.setString(2, "%" + keyword + "%");
        countStmt.setString(3, "%" + keyword + "%");
} else {
    // Normal query
   countSql = "SELECT COUNT(*) FROM students";
    countStmt = conn.prepareStatement(countSql); 
}      

      ResultSet countRs = countStmt.executeQuery();
    if (countRs.next()) {
        totalRecords = countRs.getInt(1);
    }
    totalPages = (int) Math.ceil((double) totalRecords / recordsPerPage);

     String sql;
    if (keyword != null && !keyword.trim().isEmpty()) {
        sql = "SELECT * FROM students WHERE full_name LIKE ? OR student_code LIKE ? OR major LIKE ? ORDER BY " + sortBy + " " + order + " LIMIT ? OFFSET ? ";
        pstmt = conn.prepareStatement(sql);
        pstmt.setString(1, "%" + keyword + "%");
        pstmt.setString(2, "%" + keyword + "%");
        pstmt.setString(3, "%" + keyword + "%");
        pstmt.setInt(4, recordsPerPage);
        pstmt.setInt(5, offset);
    } else {
        sql = "SELECT * FROM students ORDER BY "  + sortBy + " " + order + " LIMIT ? OFFSET ? ";
        pstmt = conn.prepareStatement(sql);
        pstmt.setInt(1, recordsPerPage);
        pstmt.setInt(2, offset);
    }
    
    rs = pstmt.executeQuery();
    boolean hasResults = false;
        while (rs.next()) {
            hasResults =true;
            int id = rs.getInt("id");
            String studentCode = rs.getString("student_code");
            String fullName = rs.getString("full_name");
            String email = rs.getString("email");
            String major = rs.getString("major");
            Timestamp createdAt = rs.getTimestamp("created_at");
%>
            <tr>
                <td><input type="checkbox" name="studentIds" value="<%= id %>"></td>
                <td><%= id %></td>
                <td><%= studentCode %></td>
                <td><%= fullName %></td>
                <td><%= email != null ? email : "N/A" %></td>
                <td><%= major != null ? major : "N/A" %></td>
                <td><%= createdAt %></td>
                <td>
                    <a href="edit_student.jsp?id=<%= id %>" class="action-link">✏️ Edit</a>
                    <a href="delete_student.jsp?id=<%= id %>" 
                       class="action-link delete-link"
                       onclick="return confirm('Are you sure?')">🗑️ Delete</a>
                </td>
            </tr>
<%
        }
    } catch (ClassNotFoundException e) {
        out.println("<tr><td colspan='7'>Error: JDBC Driver not found!</td></tr>");
        e.printStackTrace();
    } catch (SQLException e) {
        out.println("<tr><td colspan='7'>Database Error: " + e.getMessage() + "</td></tr>");
        e.printStackTrace();
    } finally {
        try {
            if (rs != null) rs.close();
            if (stmt != null) stmt.close();
            if (conn != null) conn.close();
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
%>
        </tbody>
    </table>
    </div>
    </form>
        
        <div class="pagination">
    <% if (currentPage > 1) { %>
        <a href="list_students.jsp?page=<%= currentPage - 1 %>">Previous</a>
    <% } %>
    
    <% for (int i = 1; i <= totalPages; i++) { %>
        <% if (i == currentPage) { %>
            <strong><%= i %></strong>
        <% } else { %>
            <a href="list_students.jsp?page=<%= i %>"><%= i %></a>
        <% } %>
    <% } %>
    
    <% if (currentPage < totalPages) { %>
        <a href="list_students.jsp?page=<%= currentPage + 1 %>">Next</a>
    <% } %>
</div>
 <script>
 function toggleSelectAll(source) {
            const checkboxes = document.querySelectorAll('input[name="studentIds"]');
            checkboxes.forEach(cb => cb.checked = source.checked);
        }

        function confirmBulkDelete() {
            const selected = document.querySelectorAll('input[name="studentIds"]:checked');
            if (selected.length === 0) {
                alert("Select at least one student to delete");
                return false;
            }
            return confirm("Are you sure you want to delete the selected students?");
        }
        setTimeout(() => {
            document.querySelectorAll('.message').forEach(msg => msg.style.display = 'none');
        }, 3000);
</script>
</body>
</html>
