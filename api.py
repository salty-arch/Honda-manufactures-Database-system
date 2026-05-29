"""
Honda DMS — Flask API Server
Run: python api.py
Then open honda_dms.html in your browser.
Requires: pip install flask flask-cors pyodbc
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import pyodbc

app = Flask(__name__)
CORS(app)   # allow the HTML file to call this API from any origin

# ── DATABASE ──────────────────────────────────────────────────────────────────
def get_connection():
    return pyodbc.connect(
        "Driver={SQL Server};"
        "Server=DESKTOP-K0M3A0H;"   # ← change to your server name
        "Database=honda_dms;"
        "Trusted_Connection=yes;"
    )

def run_query(sql, params=()):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(sql, params)
    cols = [d[0] for d in cursor.description]
    rows = [list(row) for row in cursor.fetchall()]
    conn.close()
    return cols, rows

def run_write(sql, params=()):
    conn = get_connection()
    conn.cursor().execute(sql, params)
    conn.commit()
    conn.close()

# ── GENERIC QUERY ENDPOINT ────────────────────────────────────────────────────
@app.route("/query", methods=["POST"])
def query():
    """
    POST /query
    Body: { "sql": "SELECT ...", "params": [] }
    Returns: { "cols": [...], "rows": [[...], ...], "count": N }
    """
    data = request.get_json()
    sql    = data.get("sql", "")
    params = data.get("params", [])
    try:
        cols, rows = run_query(sql, params)
        # Convert None to empty string for JSON
        rows = [["" if v is None else v for v in row] for row in rows]
        return jsonify({"cols": cols, "rows": rows, "count": len(rows)})
    except Exception as e:
        return jsonify({"error": str(e)}), 400

# ── GENERIC WRITE ENDPOINT ────────────────────────────────────────────────────
@app.route("/write", methods=["POST"])
def write():
    """
    POST /write
    Body: { "sql": "INSERT/UPDATE ...", "params": [] }
    Returns: { "ok": true } or { "error": "..." }
    """
    data = request.get_json()
    sql    = data.get("sql", "")
    params = data.get("params", [])
    try:
        run_write(sql, params)
        return jsonify({"ok": True})
    except Exception as e:
        return jsonify({"error": str(e)}), 400

# ── STORED PROCEDURE ENDPOINTS ────────────────────────────────────────────────
@app.route("/register-sale", methods=["POST"])
def register_sale():
    """
    POST /register-sale
    Body: { "vin", "customer_id", "dealership_id", "agreed_price",
            "discount", "tax", "payment_mode" }
    Calls sp_RegisterSale stored procedure.
    """
    d = request.get_json()
    try:
        run_write("""
            EXEC sp_RegisterSale
                @vin           = ?,
                @customer_id   = ?,
                @dealership_id = ?,
                @agreed_price  = ?,
                @discount      = ?,
                @tax           = ?,
                @payment_mode  = ?
        """, (
            d["vin"], d["customer_id"], d["dealership_id"],
            d["agreed_price"], d.get("discount", 0), d.get("tax", 0),
            d["payment_mode"]
        ))
        return jsonify({"ok": True})
    except Exception as e:
        return jsonify({"error": str(e)}), 400

@app.route("/book-service", methods=["POST"])
def book_service():
    """
    POST /book-service
    Body: { "customer_id", "dealership_id", "vin",
            "appointment_date", "service_type", "technician_name" }
    Calls sp_BookService stored procedure.
    """
    d = request.get_json()
    try:
        run_write("""
            EXEC sp_BookService
                @customer_id      = ?,
                @dealership_id    = ?,
                @vin              = ?,
                @appointment_date = ?,
                @service_type     = ?,
                @technician_name  = ?
        """, (
            d["customer_id"], d["dealership_id"], d["vin"],
            d["appointment_date"], d["service_type"],
            d.get("technician_name", None)
        ))
        return jsonify({"ok": True})
    except Exception as e:
        return jsonify({"error": str(e)}), 400

@app.route("/customer-profile/<int:customer_id>", methods=["GET"])
def customer_profile(customer_id):
    """
    GET /customer-profile/<customer_id>
    Returns all three result sets from sp_CustomerProfile.
    """
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("EXEC sp_CustomerProfile @customer_id = ?", (customer_id,))

        # Result set 1 — customer info
        cols1 = [d[0] for d in cursor.description]
        rows1 = [["" if v is None else v for v in r] for r in cursor.fetchall()]

        # Result set 2 — contracts
        cursor.nextset()
        cols2 = [d[0] for d in cursor.description]
        rows2 = [["" if v is None else v for v in r] for r in cursor.fetchall()]

        # Result set 3 — service history
        cursor.nextset()
        cols3 = [d[0] for d in cursor.description]
        rows3 = [["" if v is None else v for v in r] for r in cursor.fetchall()]

        conn.close()
        return jsonify({
            "customer":  {"cols": cols1, "rows": rows1},
            "contracts": {"cols": cols2, "rows": rows2},
            "service":   {"cols": cols3, "rows": rows3},
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 400

@app.route("/monthly-report", methods=["POST"])
def monthly_report():
    """
    POST /monthly-report
    Body: { "dealership_id": 1, "year": 2024, "month": 1 }
    Returns sales detail + summary from sp_MonthlySalesReport.
    """
    d = request.get_json()
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute(
            "EXEC sp_MonthlySalesReport @dealership_id=?, @year=?, @month=?",
            (d["dealership_id"], d["year"], d["month"])
        )
        cols1  = [x[0] for x in cursor.description]
        rows1  = [["" if v is None else v for v in r] for r in cursor.fetchall()]
        cursor.nextset()
        cols2  = [x[0] for x in cursor.description]
        rows2  = [["" if v is None else v for v in r] for r in cursor.fetchall()]
        conn.close()
        return jsonify({
            "detail":  {"cols": cols1, "rows": rows1},
            "summary": {"cols": cols2, "rows": rows2},
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 400

# ── HEALTH CHECK ──────────────────────────────────────────────────────────────
@app.route("/ping", methods=["GET"])
def ping():
    try:
        run_query("SELECT 1 AS ok")
        return jsonify({"status": "connected", "database": "honda_dms"})
    except Exception as e:
        return jsonify({"status": "disconnected", "error": str(e)}), 500

# ── RUN ───────────────────────────────────────────────────────────────────────
from flask import Flask, request, jsonify, send_file

@app.route("/")
def home():
    return send_file("honda_dms.html")


if __name__ == "__main__":
    print("Honda DMS API starting on http://localhost:5000")
    print("Open honda_dms.html in your browser.")
    app.run(debug=True, port=5000)