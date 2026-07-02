from flask import render_template, request, jsonify, session
from db_connection import execute_query
from . import admin_required


def init_routes(app):
    @app.route("/procedures")
    def procedures():
        return render_template("procedures.html")

    @app.route("/api/execute", methods=["POST"])
    def api_execute():
        if not session.get("is_admin"):
            return jsonify({"success": False, "error": "Admin access required to execute procedures."})
        sql = request.json.get("sql")
        params = request.json.get("params", [])
        try:
            cols, rows, notices = execute_query(sql, params)
            if cols:
                return jsonify({"success": True, "columns": cols, "rows": [[str(c) if c is not None else "" for c in r] for r in rows], "notices": notices})
            return jsonify({"success": True, "notices": notices})
        except Exception as e:
            return jsonify({"success": False, "error": str(e)})

    @app.route("/api/function", methods=["POST"])
    def api_function():
        sql = request.json.get("sql", "").strip()
        if not sql.upper().lstrip().startswith("SELECT"):
            return jsonify({"success": False, "error": "Only SELECT queries allowed."})
        try:
            cols, rows, notices = execute_query(sql)
            return jsonify({"success": True, "columns": cols, "rows": [[str(c) if c is not None else "" for c in r] for r in rows], "notices": notices})
        except Exception as e:
            return jsonify({"success": False, "error": str(e)})
