from flask import request, redirect, url_for, flash, session
import os


def init_routes(app):
    ADMIN_CODE = os.environ.get("ADMIN_CODE", "admin123")

    @app.route("/admin/login", methods=["POST"])
    def admin_login():
        code = request.form.get("code", "")
        if code == ADMIN_CODE:
            session["is_admin"] = True
            flash("Logged in as admin.", "success")
        else:
            flash("Invalid admin code.", "error")
        return redirect(request.referrer or url_for("index"))

    @app.route("/admin/logout")
    def admin_logout():
        session.pop("is_admin", None)
        flash("Logged out.", "success")
        return redirect(url_for("index"))
