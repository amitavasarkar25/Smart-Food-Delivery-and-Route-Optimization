
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.text.SimpleDateFormat" %>

<%!
    private String escapeHtml(Object value) {
        if (value == null) return "";

        return String.valueOf(value)
                .replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&#39;");
    }

    private int getStatusStep(String status) {
        if ("PLACED".equals(status)) return 1;
        if ("PREPARING".equals(status)) return 2;
        if ("OUT_FOR_DELIVERY".equals(status)) return 3;
        if ("DELIVERED".equals(status)) return 4;
        return 0;
    }

    private String formatTimestamp(Object value) {
        if (value == null) return "Time unavailable";

        if (value instanceof java.util.Date) {
            return new SimpleDateFormat("dd MMM yyyy, hh:mm a")
                    .format((java.util.Date) value);
        }

        return String.valueOf(value);
    }

    private String readableStatus(Object value) {
        if (value == null) return "Unknown";
        return String.valueOf(value).replace("_", " ");
    }
%>

<%
    List<Map<String, Object>> orders =
            (List<Map<String, Object>>) request.getAttribute("orders");

    if (orders == null) {
        orders = java.util.Collections.emptyList();
    }

    String context = request.getContextPath();
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <title>Track Orders | SmartFoodDelivery</title>

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
            background: #f4f7f5;
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
            margin-left: 15px;
        }

        header a:hover {
            text-decoration: underline;
        }

        .container {
            width: 92%;
            max-width: 1000px;
            margin: 35px auto;
        }

        .page-heading {
            margin-bottom: 25px;
        }

        .page-heading h1 {
            margin-bottom: 8px;
            color: #218838;
        }

        .page-heading p {
            color: #687078;
        }

        .order-card {
            background: white;
            border-radius: 12px;
            padding: 25px;
            margin-bottom: 25px;
            box-shadow: 0 4px 15px rgba(0, 0, 0, 0.06);
        }

        .order-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 12px;
            flex-wrap: wrap;
            padding-bottom: 18px;
            border-bottom: 1px solid #e5e7eb;
        }

        .order-header h3 {
            margin: 0;
        }

        .amount {
            font-size: 20px;
            color: #218838;
            font-weight: bold;
        }

        .status-label {
            display: inline-block;
            margin-top: 12px;
            padding: 7px 12px;
            background: #e8f5e9;
            color: #19692c;
            border-radius: 20px;
            font-size: 13px;
            font-weight: bold;
        }

        .timeline {
            display: flex;
            justify-content: space-between;
            position: relative;
            margin: 35px 0;
            gap: 5px;
        }

        .timeline::before {
            content: "";
            position: absolute;
            height: 4px;
            background: #dfe5e1;
            top: 17px;
            left: 12%;
            right: 12%;
        }

        .timeline-progress {
            position: absolute;
            height: 4px;
            background: #218838;
            top: 17px;
            left: 12%;
            transition: width 0.3s;
        }

        .step {
            position: relative;
            z-index: 1;
            width: 25%;
            text-align: center;
            font-size: 12px;
            color: #7b8580;
        }

        .circle {
            width: 36px;
            height: 36px;
            margin: 0 auto 10px;
            display: flex;
            align-items: center;
            justify-content: center;
            border-radius: 50%;
            background: #dfe5e1;
            color: #58635c;
            font-weight: bold;
        }

        .step.completed {
            color: #19692c;
            font-weight: bold;
        }

        .step.completed .circle {
            background: #218838;
            color: white;
        }

        .details {
            background: #f8faf9;
            padding: 15px;
            border-radius: 8px;
            line-height: 1.8;
            font-size: 14px;
            overflow-wrap: anywhere;
        }

        .delivery-person {
            color: #19692c;
            font-weight: bold;
        }

        .unassigned {
            color: #687078;
            font-style: italic;
        }

        /* Customer delivery route map */
        .map-section {
            margin-top: 22px;
            padding-top: 20px;
            border-top: 1px solid #e5e7eb;
        }

        .map-section h4 {
            margin: 0 0 8px;
            font-size: 17px;
        }

        .map-description {
            color: #687078;
            font-size: 13px;
            line-height: 1.5;
        }

        .delivery-map {
            width: 100%;
            height: 320px;
            margin-top: 12px;
            border: 1px solid #d7dde2;
            border-radius: 8px;
            z-index: 1;
        }

        .route-info {
            font-size: 14px;
            line-height: 1.6;
            margin: 10px 0 0;
            color: #344054;
            overflow-wrap: anywhere;
        }

        .gps-info {
            font-size: 13px;
            line-height: 1.5;
            margin: 6px 0 0;
            color: #19692c;
            overflow-wrap: anywhere;
        }

        .delivery-complete {
            display: none;
            margin-top: 12px;
            padding: 13px 15px;
            border: 1px solid #b7e4c7;
            border-radius: 8px;
            background: #e8f5e9;
            color: #19692c;
            font-weight: bold;
        }

        .delivery-complete.visible {
            display: block;
        }

        /* Status history */
        .history-section {
            margin-top: 25px;
            padding-top: 20px;
            border-top: 1px solid #e5e7eb;
        }

        .history-section h4 {
            margin: 0 0 20px;
            font-size: 17px;
            color: #263238;
        }

        .history-list {
            list-style: none;
            margin: 0;
            padding: 0;
        }

        .history-item {
            position: relative;
            display: flex;
            gap: 14px;
            padding-bottom: 22px;
        }

        .history-item:last-child {
            padding-bottom: 0;
        }

        .history-marker {
            flex-shrink: 0;
            width: 30px;
            height: 30px;
            display: flex;
            justify-content: center;
            align-items: center;
            border-radius: 50%;
            background: #e8f5e9;
            color: #218838;
            font-weight: bold;
            font-size: 14px;
            z-index: 1;
        }

        .history-item:not(:last-child)::after {
            content: "";
            position: absolute;
            left: 14px;
            top: 30px;
            bottom: 0;
            width: 2px;
            background: #d8e8dc;
        }

        .history-content {
            padding-top: 3px;
            min-width: 0;
        }

        .history-status {
            font-weight: bold;
            color: #263238;
            margin-bottom: 5px;
        }

        .history-time {
            font-size: 13px;
            color: #687078;
            line-height: 1.5;
            overflow-wrap: anywhere;
        }

        .history-empty {
            color: #687078;
            font-size: 14px;
            font-style: italic;
        }

        .empty {
            text-align: center;
            background: white;
            padding: 45px 20px;
            border-radius: 12px;
        }

        .empty a,
        .back-link {
            color: #218838;
            text-decoration: none;
            font-weight: bold;
        }

        .back-link {
            display: inline-block;
            margin-top: 10px;
        }

        @media (max-width: 500px) {
            .container {
                width: 95%;
                margin-top: 20px;
            }

            .order-card {
                padding: 16px;
            }

            .step {
                font-size: 10px;
            }

            .circle {
                width: 30px;
                height: 30px;
                font-size: 12px;
            }

            .timeline::before {
                top: 14px;
            }

            .timeline-progress {
                top: 14px;
            }

            header a {
                margin-left: 0;
                margin-right: 12px;
            }

            .delivery-map {
                height: 260px;
            }
        }
    </style>
</head>

<body>

<header>
    <h2>🍽️ SmartFoodDelivery</h2>

    <nav>
        <a href="<%= context %>/customer/dashboard.jsp">Dashboard</a>
        <a href="<%= context %>/orders">My Orders</a>
        <a href="<%= context %>/logout">Logout</a>
    </nav>
</header>

<main class="container">

    <div class="page-heading">
        <h1>Track Your Orders</h1>
        <p>Follow your order from placement to delivery.</p>
    </div>

    <% if (orders.isEmpty()) { %>

        <div class="empty">
            <h2>No orders yet</h2>
            <p>You haven't placed any orders yet.</p>
            <a href="<%= context %>/food/menu">Browse Food Menu</a>
        </div>

    <% } else { %>

        <% for (Map<String, Object> order : orders) {
            String status = String.valueOf(order.get("status"));
            int step = getStatusStep(status);
            int progressWidth = step <= 1 ? 0 : (step - 1) * 25;

            Object deliveryPersonName =
                    order.get("deliveryPersonName");

            boolean isAssigned =
                    deliveryPersonName != null
                    && !String.valueOf(deliveryPersonName)
                            .trim().isEmpty();

            List<Map<String, Object>> statusHistory =
                    (List<Map<String, Object>>) order.get("statusHistory");

            if (statusHistory == null) {
                statusHistory = java.util.Collections.emptyList();
            }
        %>

            <section class="order-card">

                <div class="order-header">
                    <div>
                        <h3>Order #<%= escapeHtml(order.get("id")) %></h3>

                        <span class="status-label">
                            <%= escapeHtml(readableStatus(status)) %>
                        </span>
                    </div>

                    <div class="amount">
                        ₹<%= escapeHtml(order.get("totalAmount")) %>
                    </div>
                </div>

                <!-- Four-stage order progress -->
                <div class="timeline">

                    <div class="timeline-progress"
                         style="width: <%= progressWidth %>%;">
                    </div>

                    <div class="step <%= step >= 1 ? "completed" : "" %>">
                        <div class="circle">1</div>
                        <div>Placed</div>
                    </div>

                    <div class="step <%= step >= 2 ? "completed" : "" %>">
                        <div class="circle">2</div>
                        <div>Preparing</div>
                    </div>

                    <div class="step <%= step >= 3 ? "completed" : "" %>">
                        <div class="circle">3</div>
                        <div>On the Way</div>
                    </div>

                    <div class="step <%= step >= 4 ? "completed" : "" %>">
                        <div class="circle">4</div>
                        <div>Delivered</div>
                    </div>

                </div>

                <!-- Order details -->
                <div class="details">
                    <strong>Delivery Address:</strong>
                    <%= escapeHtml(order.get("address")) %>
                    <br>

                    <strong>Payment Method:</strong>
                    <%= escapeHtml(order.get("paymentMethod")) %>
                    <br>

                    <strong>Order Date:</strong>
                    <%= escapeHtml(formatTimestamp(order.get("createdAt"))) %>
                    <br>

                    <strong>Delivery Person:</strong>

                    <% if (isAssigned) { %>
                        <span class="delivery-person">
                            <%= escapeHtml(deliveryPersonName) %>
                        </span>
                    <% } else { %>
                        <span class="unassigned">
                            Not assigned yet
                        </span>
                    <% } %>
                </div>

                <!-- Delivery map and road route -->
                <div class="map-section">
                    <h4>Delivery Route</h4>

                    <p class="map-description">
                        View the demo restaurant location, your delivery
                        location, and the estimated driving route.
                    </p>

                    <div
                        class="delivery-map"
                        id="customer-map-<%= escapeHtml(order.get("id")) %>"
                        data-address="<%= escapeHtml(order.get("address")) %>"
                        data-order-id="<%= escapeHtml(order.get("id")) %>"
                        data-order-status="<%= escapeHtml(status) %>"
                        data-location-url="<%= context %>/orders/location">
                    </div>

                    <p class="route-info" aria-live="polite">
                        Loading map and route...
                    </p>
                    <p class="gps-info" aria-live="polite">
                        Live delivery location will appear when the order is out for delivery.
                    </p>
                    <div class="delivery-complete" role="status" aria-live="polite">
                        ✓ Order Delivered Successfully
                    </div>
                </div>

                <!-- Full order status history -->
                <div class="history-section">
                    <h4>Order Status History</h4>

                    <% if (statusHistory.isEmpty()) { %>

                        <p class="history-empty">
                            No status history is available yet.
                        </p>

                    <% } else { %>

                        <ul class="history-list">

                            <% for (int i = 0;
                                    i < statusHistory.size(); i++) {

                                Map<String, Object> event =
                                        statusHistory.get(i);

                                Object eventStatus = event.get("status");
                                Object changedAt = event.get("changedAt");
                            %>

                                <li class="history-item">

                                    <div class="history-marker">
                                        &#10003;
                                    </div>

                                    <div class="history-content">
                                        <div class="history-status">
                                            <%= escapeHtml(
                                                    readableStatus(eventStatus)) %>
                                        </div>

                                        <div class="history-time">
                                            <%= escapeHtml(
                                                    formatTimestamp(changedAt)) %>
                                        </div>
                                    </div>

                                </li>

                            <% } %>

                        </ul>

                    <% } %>
                </div>

            </section>

        <% } %>

    <% } %>

    <a class="back-link" href="<%= context %>/customer/dashboard.jsp">
        ← Back to Dashboard
    </a>

</main>

<!-- Initialize customer maps and calculate road routes -->
<script>
document.addEventListener("DOMContentLoaded", function () {
    const restaurant = {
        lat: 30.749611,
        lon: 76.629417
    };

    document.querySelectorAll(".delivery-map").forEach(async function (element) {
        const info = element.nextElementSibling;
        const gpsInfo = info.nextElementSibling;
        let orderStatus = element.dataset.orderStatus;
        const orderId = element.dataset.orderId;
        const orderCard = element.closest(".order-card");
        const statusLabel = orderCard ? orderCard.querySelector(".status-label") : null;
        const deliveredNotice = element.parentElement.querySelector(".delivery-complete");
        const locationUrl = element.dataset.locationUrl;

        let deliveryMarker = null;
        let customerPoint = null;
        let routeLine = null;
        let lastRoutedPoint = null;
        let lastRouteRequestAt = 0;
        let routeRequestInProgress = false;
        let gpsPoll = null;

        try {
            if (typeof L === "undefined") {
                throw new Error("Leaflet library did not load.");
            }

            const map = L.map(element).setView([restaurant.lat, restaurant.lon], 13);

            L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
                attribution: "&copy; OpenStreetMap contributors",
                maxZoom: 19
            }).addTo(map);

            L.marker([restaurant.lat, restaurant.lon])
                .addTo(map)
                .bindPopup("Restaurant — Kharar, Punjab");

            const address = element.dataset.address;
            if (!address || !address.trim()) {
                info.textContent = "No delivery address available.";
                gpsInfo.textContent = "Live GPS cannot be shown without a delivery address.";
                return;
            }

            const geocodeUrl =
                "https://nominatim.openstreetmap.org/search?format=json&limit=1&q=" +
                encodeURIComponent(address + ", Kharar, Punjab, India");

            const geoResponse = await fetch(geocodeUrl);
            if (!geoResponse.ok) throw new Error("Address lookup failed.");

            const locations = await geoResponse.json();
            if (!locations.length) {
                info.textContent = "Address not found. Please enter a more complete delivery address.";
                gpsInfo.textContent = "Live GPS will appear after the delivery address can be located.";
                return;
            }

            customerPoint = {
                lat: Number(locations[0].lat),
                lon: Number(locations[0].lon)
            };

            L.marker([customerPoint.lat, customerPoint.lon])
                .addTo(map)
                .bindPopup("Your Delivery Location");

            // Start with the planned route from the restaurant to the customer.
            await updateRoute({ lat: restaurant.lat, lon: restaurant.lon }, false);

            async function updateRoute(origin, fitMap) {
                if (!customerPoint || routeRequestInProgress) return;

                routeRequestInProgress = true;
                try {
                    const routeUrl =
                        "https://router.project-osrm.org/route/v1/driving/" +
                        origin.lon + "," + origin.lat + ";" +
                        customerPoint.lon + "," + customerPoint.lat +
                        "?overview=full&geometries=geojson";

                    const response = await fetch(routeUrl);
                    if (!response.ok) throw new Error("Route service unavailable.");

                    const data = await response.json();
                    if (data.code !== "Ok" || !data.routes || !data.routes.length) {
                        throw new Error("No road route could be found.");
                    }

                    const route = data.routes[0];
                    if (routeLine) {
                        routeLine.setLatLngs(
                            L.GeoJSON.coordsToLatLngs(route.geometry.coordinates, 0)
                        );
                    } else {
                        routeLine = L.geoJSON(route.geometry, {
                            style: { color: "#16804a", weight: 5, opacity: 0.85 }
                        }).addTo(map);
                    }

                    if (fitMap) {
                        map.fitBounds(routeLine.getBounds(), { padding: [25, 25] });
                    }

                    const distanceKm = (route.distance / 1000).toFixed(2);
                    const durationMinutes = Math.round(route.duration / 60);
                    info.textContent = (deliveryMarker
                        ? "Remaining road distance: "
                        : "Road distance from restaurant: ") +
                        distanceKm + " km | Estimated " +
                        (deliveryMarker ? "remaining " : "") +
                        "travel time: " + durationMinutes + " minutes";
                } catch (error) {
                    console.warn("Route refresh error:", error);
                    if (!routeLine) {
                        info.textContent = "Map loaded, but the road route is temporarily unavailable.";
                    }
                } finally {
                    routeRequestInProgress = false;
                }
            }

            function showLastKnownLocation(location) {
                if (location.latitude == null || location.longitude == null ||
                    !Number.isFinite(Number(location.latitude)) ||
                    !Number.isFinite(Number(location.longitude))) {
                    return false;
                }

                const point = {
                    lat: Number(location.latitude),
                    lon: Number(location.longitude)
                };

                if (!deliveryMarker) {
                    deliveryMarker = L.marker([point.lat, point.lon])
                        .addTo(map)
                        .bindPopup("Delivery Person — Last Known Location");
                    map.panTo([point.lat, point.lon]);
                } else {
                    deliveryMarker.setLatLng([point.lat, point.lon]);
                }
                return point;
            }

            function markDelivered(location) {
                orderStatus = "DELIVERED";
                element.dataset.orderStatus = "DELIVERED";

                if (gpsPoll !== null) {
                    window.clearInterval(gpsPoll);
                    gpsPoll = null;
                }

                if (statusLabel) statusLabel.textContent = "DELIVERED";
                if (deliveredNotice) deliveredNotice.classList.add("visible");

                if (orderCard) {
                    orderCard.querySelectorAll(".timeline .step").forEach(function (step) {
                        step.classList.add("completed");
                    });
                    const progress = orderCard.querySelector(".timeline-progress");
                    if (progress) progress.style.width = "75%";
                }

                const lastPoint = showLastKnownLocation(location);
                if (lastPoint) {
                    const updatedAt = location.updatedAt
                        ? new Date(location.updatedAt).toLocaleString()
                        : "time unavailable";
                    gpsInfo.textContent =
                        "Delivery completed. Showing the last known delivery-person location, updated: " +
                        updatedAt + ". Live GPS polling has stopped.";
                    if (customerPoint && !routeRequestInProgress) {
                        lastRoutedPoint = lastPoint;
                        lastRouteRequestAt = Date.now();
                        updateRoute(lastPoint, false);
                    }
                } else {
                    gpsInfo.textContent =
                        "Order delivered. No delivery GPS location was recorded; live GPS polling has stopped.";
                }
            }

            async function refreshDeliveryLocation() {
                if (orderStatus === "DELIVERED") {
                    if (gpsPoll !== null) {
                        window.clearInterval(gpsPoll);
                        gpsPoll = null;
                    }
                    return;
                }

                try {
                    const response = await fetch(
                        locationUrl + "?orderId=" + encodeURIComponent(orderId),
                        { headers: { "Accept": "application/json" }, cache: "no-store" }
                    );
                    if (!response.ok) throw new Error("Location request failed.");

                    const location = await response.json();

                    if (location.status) {
                        orderStatus = String(location.status).toUpperCase();
                        element.dataset.orderStatus = orderStatus;
                        if (statusLabel) {
                            statusLabel.textContent = orderStatus.replace(/_/g, " ");
                        }
                    }

                    if (orderStatus === "DELIVERED") {
                        markDelivered(location);
                        return;
                    }

                    if (orderStatus !== "OUT_FOR_DELIVERY") {
                        gpsInfo.textContent =
                            "Live GPS tracking starts when the order is out for delivery. Current status: " +
                            (orderStatus || "Unknown").replace(/_/g, " ") + ".";
                        return;
                    }

                    const point = showLastKnownLocation(location);
                    if (!location.success || !point) {
                        gpsInfo.textContent =
                            location.message || "Waiting for the delivery person's GPS location...";
                        return;
                    }

                    if (deliveryMarker) {
                        deliveryMarker.bindPopup("Delivery Person — Live Location");
                    }

                    const updatedAt = location.updatedAt
                        ? new Date(location.updatedAt).toLocaleString()
                        : "time unavailable";
                    gpsInfo.textContent =
                        "Live delivery location updated: " + updatedAt +
                        ". Position refreshes automatically.";

                    // Refresh the remaining route only after meaningful movement or 15 seconds.
                    const now = Date.now();
                    let movedEnough = !lastRoutedPoint;
                    if (lastRoutedPoint) {
                        const distanceMoved = map.distance(
                            [lastRoutedPoint.lat, lastRoutedPoint.lon],
                            [point.lat, point.lon]
                        );
                        movedEnough = distanceMoved >= 50;
                    }

                    if (customerPoint && !routeRequestInProgress &&
                        (movedEnough || now - lastRouteRequestAt >= 15000)) {
                        lastRoutedPoint = point;
                        lastRouteRequestAt = now;
                        await updateRoute(point, false);
                    }
                } catch (gpsError) {
                    console.warn("Live delivery location error:", gpsError);
                    gpsInfo.textContent =
                        "Live GPS location is not available yet. The delivery person must allow location access.";
                }
            }

            await refreshDeliveryLocation();
            if (orderStatus !== "DELIVERED") {
                gpsPoll = window.setInterval(refreshDeliveryLocation, 5000);
            }

            window.addEventListener("pagehide", function () {
                if (gpsPoll !== null) {
                    window.clearInterval(gpsPoll);
                    gpsPoll = null;
                }
            });

        } catch (error) {
            console.error("Customer delivery map error:", error);
            info.textContent =
                "Could not load the map or route. Check your internet connection and refresh the page.";
            gpsInfo.textContent = "Live GPS is unavailable while the map cannot load.";
        }
    });
});
</script>

</body>
</html>
