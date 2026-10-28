<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>

<%!
    private String escapeHtml(Object value) {
        if (value == null) return "";

        String text = String.valueOf(value);

        return text.replace("&", "&amp;")
                   .replace("<", "&lt;")
                   .replace(">", "&gt;")
                   .replace("\"", "&quot;")
                   .replace("'", "&#39;");
    }
%>

<%
    List<Map<String, Object>> orders =
        (List<Map<String, Object>>) request.getAttribute("orders");

    if (orders == null) {
        orders = java.util.Collections.emptyList();
    }

    String context = request.getContextPath();

    String message = (String) session.getAttribute("deliveryMessage");
    session.removeAttribute("deliveryMessage");

    String userName = (String) session.getAttribute("userName");
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <title>Delivery Dashboard | SmartFoodDelivery</title>

    <!-- Leaflet map library -->
    <link rel="stylesheet"
          href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css">

    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>

    <style>
        * {
            box-sizing: border-box;
        }

        body {
            margin: 0;
            font-family: Arial, sans-serif;
            background: #f4f6f9;
            color: #263238;
        }

        header {
            background: #17252a;
            color: white;
            padding: 20px 5%;
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 12px;
        }

        header h2 {
            margin: 0;
        }

        header a {
            color: white;
            text-decoration: none;
        }

        header a:hover {
            text-decoration: underline;
        }

        .container {
            width: 92%;
            max-width: 1200px;
            margin: 30px auto;
        }

        .welcome {
            margin-bottom: 22px;
        }

        .welcome h1 {
            margin-bottom: 8px;
        }

        .summary {
            background: white;
            padding: 18px 22px;
            border-radius: 10px;
            margin-bottom: 22px;
            box-shadow: 0 3px 12px #00000010;
        }

        .message {
            padding: 12px 15px;
            margin-bottom: 18px;
            background: #d1e7dd;
            color: #0f5132;
            border-radius: 6px;
        }

        .orders {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
            gap: 20px;
        }

        .order-card {
            background: white;
            padding: 22px;
            border-radius: 10px;
            box-shadow: 0 3px 12px #00000010;
            min-width: 0;
        }

        .order-card h3 {
            margin-top: 0;
            color: #176b87;
        }

        .detail {
            margin: 12px 0;
            line-height: 1.5;
            overflow-wrap: anywhere;
        }

        .status {
            display: inline-block;
            padding: 6px 10px;
            border-radius: 5px;
            background: #fff3cd;
            font-weight: bold;
            font-size: 13px;
        }

        .route-heading {
            margin-bottom: 8px;
        }

        .delivery-map {
            height: 300px;
            width: 100%;
            border-radius: 8px;
            margin-top: 10px;
            border: 1px solid #d7dde2;
            z-index: 1;
        }

        .route-info {
            font-size: 14px;
            line-height: 1.5;
            color: #344054;
            margin-top: 10px;
        }

        .gps-info {
            font-size: 13px;
            line-height: 1.5;
            color: #176b87;
            margin-top: 6px;
            overflow-wrap: anywhere;
        }

        label {
            display: block;
            margin: 16px 0 8px;
            font-weight: bold;
        }

        select {
            width: 100%;
            padding: 10px;
            border: 1px solid #ccd2d7;
            border-radius: 5px;
            background: white;
        }

        button {
            width: 100%;
            margin-top: 12px;
            padding: 12px;
            border: none;
            border-radius: 5px;
            background: #16804a;
            color: white;
            cursor: pointer;
            font-size: 14px;
        }

        button:hover {
            background: #10663a;
        }

        .delivered {
            background: #d1e7dd;
            color: #0f5132;
            padding: 12px;
            border-radius: 5px;
            text-align: center;
            font-weight: bold;
            margin-top: 18px;
        }

        .empty {
            background: white;
            padding: 35px;
            text-align: center;
            border-radius: 10px;
            color: #667085;
        }

        @media (max-width: 600px) {
            .container {
                width: 94%;
                margin: 20px auto;
            }

            header {
                padding: 18px 4%;
            }

            .order-card {
                padding: 16px;
            }

            .delivery-map {
                height: 260px;
            }
        }
    </style>
</head>

<body>

<header>
    <h2>SmartFoodDelivery</h2>
    <a href="<%= context %>/logout">Logout</a>
</header>

<div class="container">

    <div class="welcome">
        <h1>Delivery Dashboard</h1>
        <p>
            Welcome, <strong><%= escapeHtml(userName) %></strong>.
            Here are the orders assigned to you.
        </p>
    </div>

    <% if (message != null) { %>
        <div class="message">
            <%= escapeHtml(message) %>
        </div>
    <% } %>

    <div class="summary">
        <strong>Assigned Orders:</strong>
        <%= orders.size() %>
    </div>

    <% if (orders.isEmpty()) { %>

        <div class="empty">
            <h3>No orders assigned yet</h3>
            <p>
                Orders assigned to your account by the administrator
                will appear here.
            </p>
        </div>

    <% } else { %>

        <div class="orders">

            <% for (Map<String, Object> order : orders) {
                String status = String.valueOf(order.get("status"));
                boolean isDelivered = "DELIVERED".equals(status);
            %>

                <div class="order-card">

                    <h3>
                        Order #<%= escapeHtml(order.get("id")) %>
                    </h3>

                    <div class="detail">
                        <strong>Customer:</strong><br>
                        <%= escapeHtml(order.get("customerName")) %>
                    </div>

                    <div class="detail">
                        <strong>Customer Email:</strong><br>
                        <%= escapeHtml(order.get("customerEmail")) %>
                    </div>

                    <div class="detail">
                        <strong>Delivery Address:</strong><br>
                        <%= escapeHtml(order.get("address")) %>
                    </div>

                    <!-- Delivery map and road route -->
                    <div class="detail">
                        <strong class="route-heading">Delivery Route:</strong>

                        <div
                            class="delivery-map"
                            id="delivery-map-<%= escapeHtml(order.get("id")) %>"
                            data-order-id="<%= escapeHtml(order.get("id")) %>"
                            data-order-status="<%= escapeHtml(status) %>"
                            data-address="<%= escapeHtml(order.get("address")) %>">
                        </div>

                        <p class="route-info" aria-live="polite">
                            Loading map and route...
                        </p>
                        <p class="gps-info" aria-live="polite">
                            <% if ("OUT_FOR_DELIVERY".equals(status)) { %>
                                Live GPS: waiting for location permission...
                            <% } else if (isDelivered) { %>
                                Live GPS stopped: order delivered.
                            <% } else { %>
                                Live GPS starts when the order is out for delivery.
                            <% } %>
                        </p>
                    </div>

                    <div class="detail">
                        <strong>Order Amount:</strong>
                        ₹<%= escapeHtml(order.get("totalAmount")) %>
                    </div>

                    <div class="detail">
                        <strong>Payment:</strong>
                        <%= escapeHtml(order.get("paymentMethod")) %>
                    </div>

                    <div class="detail">
                        <strong>Order Date:</strong><br>
                        <%= escapeHtml(order.get("createdAt")) %>
                    </div>

                    <div class="detail">
                        <strong>Current Status:</strong><br>
                        <span class="status">
                            <%= escapeHtml(status) %>
                        </span>
                    </div>

                    <% if (isDelivered) { %>

                        <div class="delivered">
                            Order Delivered
                        </div>

                    <% } else { %>

                        <form method="post"
                              action="<%= context %>/delivery/dashboard">

                            <input type="hidden"
                                   name="orderId"
                                   value="<%= escapeHtml(order.get("id")) %>">

                            <label for="status-<%= escapeHtml(order.get("id")) %>">
                                Update Delivery Status
                            </label>

                            <select
                                id="status-<%= escapeHtml(order.get("id")) %>"
                                name="status"
                                required>

                                <% if ("PLACED".equals(status)) { %>
                                    <option value="OUT_FOR_DELIVERY">
                                        Out for Delivery
                                    </option>
                                <% } else if ("PREPARING".equals(status)) { %>
                                    <option value="OUT_FOR_DELIVERY">
                                        Out for Delivery
                                    </option>
                                <% } else if ("OUT_FOR_DELIVERY".equals(status)) { %>
                                    <option value="DELIVERED">
                                        Delivered
                                    </option>
                                <% } %>

                            </select>

                            <button type="submit">
                                Update Order
                            </button>
                        </form>

                    <% } %>

                </div>

            <% } %>

        </div>

    <% } %>

</div>

<!-- Initialize maps, calculate road routes, and manage live GPS -->
<script>
document.addEventListener("DOMContentLoaded", function () {

    // Actual restaurant coordinates supplied for SmartFoodDelivery.
    const restaurant = {
        lat: 30.749611,
        lon: 76.629417
    };

    const contextPath = "<%= context %>";

    document.querySelectorAll(".delivery-map").forEach(async function (element) {
        const info = element.nextElementSibling;
        const gpsInfo = info ? info.nextElementSibling : null;
        const orderId = element.dataset.orderId;
        const orderStatus = element.dataset.orderStatus;

        let map;
        let driverMarker = null;
        let lastSentAt = 0;
        let gpsWatchId = null;

        async function sendGpsPosition(position) {
            if (orderStatus !== "OUT_FOR_DELIVERY") return;

            const now = Date.now();

            // Limit updates to approximately one every 10 seconds per order.
            if (now - lastSentAt < 10000) return;
            lastSentAt = now;

            const latitude = position.coords.latitude;
            const longitude = position.coords.longitude;

            if (map) {
                if (!driverMarker) {
                    driverMarker = L.marker([latitude, longitude])
                        .addTo(map)
                        .bindPopup("Your live delivery location");
                } else {
                    driverMarker.setLatLng([latitude, longitude]);
                }
            }

            if (gpsInfo) {
                gpsInfo.textContent = "Live GPS: sending location...";
            }

            try {
                const body = new URLSearchParams({
                    orderId: orderId,
                    latitude: String(latitude),
                    longitude: String(longitude)
                });

                const response = await fetch(
                    contextPath + "/delivery/location/update",
                    {
                        method: "POST",
                        headers: {
                            "Content-Type": "application/x-www-form-urlencoded;charset=UTF-8"
                        },
                        body: body.toString(),
                        credentials: "same-origin"
                    }
                );

                const result = await response.json();

                if (!response.ok || !result.success) {
                    throw new Error(result.message || "GPS update was rejected.");
                }

                if (gpsInfo) {
                    gpsInfo.textContent =
                        "Live GPS active · Last sent: " +
                        new Date().toLocaleTimeString();
                }
            } catch (error) {
                console.error("GPS update error for order " + orderId, error);

                if (gpsInfo) {
                    gpsInfo.textContent =
                        "GPS update failed: " + error.message +
                        ". Check login, assignment, and order status.";
                }
            }
        }

        function startLiveGps() {
            if (orderStatus !== "OUT_FOR_DELIVERY") return;

            if (!navigator.geolocation) {
                if (gpsInfo) {
                    gpsInfo.textContent =
                        "Live GPS unavailable: this browser does not support geolocation.";
                }
                return;
            }

            if (location.protocol !== "https:" &&
                location.hostname !== "localhost" &&
                location.hostname !== "127.0.0.1") {
                if (gpsInfo) {
                    gpsInfo.textContent =
                        "Live GPS requires HTTPS, or localhost during development.";
                }
                return;
            }

            gpsWatchId = navigator.geolocation.watchPosition(
                sendGpsPosition,
                function (error) {
                    let message = "Could not read device location.";

                    if (error.code === error.PERMISSION_DENIED) {
                        message = "Location permission denied. Allow location access in your browser settings.";
                    } else if (error.code === error.POSITION_UNAVAILABLE) {
                        message = "Device location is unavailable.";
                    } else if (error.code === error.TIMEOUT) {
                        message = "GPS request timed out. Waiting for another location update.";
                    }

                    if (gpsInfo) {
                        gpsInfo.textContent = "Live GPS: " + message;
                    }
                },
                {
                    enableHighAccuracy: true,
                    maximumAge: 5000,
                    timeout: 15000
                }
            );
        }

        // Release this order's GPS watcher when leaving or reloading the page.
        window.addEventListener("pagehide", function () {
            if (gpsWatchId !== null && navigator.geolocation) {
                navigator.geolocation.clearWatch(gpsWatchId);
                gpsWatchId = null;
            }
        });

        try {
            if (typeof L === "undefined") {
                throw new Error("Leaflet library did not load.");
            }

            map = L.map(element).setView(
                [restaurant.lat, restaurant.lon],
                13
            );

            L.tileLayer(
                "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                {
                    attribution: "&copy; OpenStreetMap contributors",
                    maxZoom: 19
                }
            ).addTo(map);

            L.marker([restaurant.lat, restaurant.lon])
                .addTo(map)
                .bindPopup("Your Restaurant — Kharar, Punjab");

            // GPS is started only for orders currently OUT_FOR_DELIVERY.
            // Delivered orders never start a GPS watcher.
            startLiveGps();

            const address = element.dataset.address;

            if (!address || !address.trim()) {
                if (info) {
                    info.textContent = "No delivery address available.";
                }
                return;
            }

            const geocodeUrl =
                "https://nominatim.openstreetmap.org/search?format=json&limit=1&q=" +
                encodeURIComponent(address + ", Kharar, Punjab, India");

            const geoResponse = await fetch(geocodeUrl);

            if (!geoResponse.ok) {
                throw new Error("Address lookup failed.");
            }

            const locations = await geoResponse.json();

            if (!locations.length) {
                if (info) {
                    info.textContent =
                        "Address not found. Please enter a more complete delivery address.";
                }
                return;
            }

            const customer = {
                lat: Number(locations[0].lat),
                lon: Number(locations[0].lon)
            };

            L.marker([customer.lat, customer.lon])
                .addTo(map)
                .bindPopup("Customer Delivery Location");

            const routeUrl =
                "https://router.project-osrm.org/route/v1/driving/" +
                restaurant.lon + "," + restaurant.lat + ";" +
                customer.lon + "," + customer.lat +
                "?overview=full&geometries=geojson";

            const routeResponse = await fetch(routeUrl);

            if (!routeResponse.ok) {
                throw new Error("Route service unavailable.");
            }

            const routeData = await routeResponse.json();

            if (
                routeData.code !== "Ok" ||
                !routeData.routes ||
                routeData.routes.length === 0
            ) {
                if (info) {
                    info.textContent = "No road route could be found.";
                }
                return;
            }

            const route = routeData.routes[0];

            const routeLine = L.geoJSON(route.geometry, {
                style: {
                    color: "#16804a",
                    weight: 5,
                    opacity: 0.85
                }
            }).addTo(map);

            map.fitBounds(routeLine.getBounds(), {
                padding: [25, 25]
            });

            const distanceKm = (route.distance / 1000).toFixed(2);
            const durationMinutes = Math.round(route.duration / 60);

            if (info) {
                info.textContent =
                    "Road distance: " + distanceKm +
                    " km | Estimated travel time: " +
                    durationMinutes + " minutes";
            }

        } catch (error) {
            console.error("Delivery map error:", error);

            if (info) {
                info.textContent =
                    "Could not load the map or route. Check your internet connection and refresh the page.";
            }
        }
    });
});
</script>

</body>
</html>
