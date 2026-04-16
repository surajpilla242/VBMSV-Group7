// search.js – Global live search for VBMSV Solutions
// Runs after DOM is built (place <script src="search.js"> just before </body>)
(function () {
    'use strict';

    var INDEX = [
        // ── Warehouse Shipments ──────────────────────────────────────────
        { label: 'OUT-40127', sub: 'Shipment · Outbound · Phoenix Distribution Hub · TRK-8821', url: 'WarehouseShipmentDetails.html?id=OUT-40127' },
        { label: 'OUT-40119', sub: 'Shipment · Outbound · San Diego Clinic Network · TRK-7714', url: 'WarehouseShipmentDetails.html?id=OUT-40119' },
        { label: 'OUT-40103', sub: 'Shipment · Outbound · Las Vegas Medical Center · TRK-6630', url: 'WarehouseShipmentDetails.html?id=OUT-40103' },
        { label: 'OUT-40098', sub: 'Shipment · Outbound · Tucson Partner Warehouse · TRK-6527', url: 'WarehouseShipmentDetails.html?id=OUT-40098' },
        { label: 'IN-87214',  sub: 'Shipment · Inbound · Fresno Consolidation Site · TRK-4592',       url: 'WarehouseShipmentDetails.html?id=IN-87214' },
        { label: 'IN-87201',  sub: 'Shipment · Inbound · Sacramento Cold Chain Node · TRK-3320',      url: 'WarehouseShipmentDetails.html?id=IN-87201' },
        { label: 'IN-87188',  sub: 'Shipment · Inbound · Reno Supply Facility · TRK-2844',            url: 'WarehouseShipmentDetails.html?id=IN-87188' },
        { label: 'IN-87180',  sub: 'Shipment · Inbound · Boise Transfer Site · TRK-2402',             url: 'WarehouseShipmentDetails.html?id=IN-87180' },

        // ── Driver Shipments ─────────────────────────────────────────────
        { label: 'SHP-2024-001', sub: 'Shipment · Los Angeles, CA \u2192 New York, NY · Delivered',    url: 'ShipmentDetails.html?id=SHP-2024-001' },
        { label: 'SHP-2024-002', sub: 'Shipment · Chicago, IL \u2192 Miami, FL · In Transit',          url: 'ShipmentDetails.html?id=SHP-2024-002' },
        { label: 'SHP-2024-003', sub: 'Shipment · Seattle, WA \u2192 Dallas, TX · Delivered',          url: 'ShipmentDetails.html?id=SHP-2024-003' },
        { label: 'SHP-2024-004', sub: 'Shipment · Boston, MA \u2192 Phoenix, AZ · Delayed',            url: 'ShipmentDetails.html?id=SHP-2024-004' },
        { label: 'SHP-2024-005', sub: 'Shipment · Denver, CO \u2192 Atlanta, GA · Pending',            url: 'ShipmentDetails.html?id=SHP-2024-005' },
        { label: 'SHP-2024-006', sub: 'Shipment · San Francisco, CA \u2192 Houston, TX · Delivered',   url: 'ShipmentDetails.html?id=SHP-2024-006' },

        // ── Batches ──────────────────────────────────────────────────────
        { label: 'BCH-0942', sub: 'Batch · DHS Logistics · 240 units · Exp Jul 10, 2026',       url: 'VendorInfo.html?q=BCH-0942' },
        { label: 'BCH-0975', sub: 'Batch · DHS Logistics · 180 units · Exp Aug 5, 2026',        url: 'VendorInfo.html?q=BCH-0975' },
        { label: 'BCH-1018', sub: 'Batch · DHS Logistics · 500 units · Exp Mar 1, 2027',        url: 'VendorInfo.html?q=BCH-1018' },
        { label: 'BCH-2201', sub: 'Batch · Arctic Bio Supply · 320 vials · Exp Jun 20, 2026',   url: 'VendorInfo.html?q=BCH-2201' },
        { label: 'BCH-2215', sub: 'Batch · Arctic Bio Supply · 150 vials · Exp Sep 15, 2026',   url: 'VendorInfo.html?q=BCH-2215' },
        { label: 'BCH-3301', sub: 'Batch · MedTech Pharma · 600 tablets · Exp May 1, 2026',     url: 'VendorInfo.html?q=BCH-3301' },
        { label: 'BCH-3318', sub: 'Batch · MedTech Pharma · 200 bottles · Exp Nov 20, 2026',    url: 'VendorInfo.html?q=BCH-3318' },
        { label: 'BCH-4401', sub: 'Batch · FreshChain Co. · 900 kg · Exp May 15, 2026',         url: 'VendorInfo.html?q=BCH-4401' },
        { label: 'BCH-4415', sub: 'Batch · FreshChain Co. · 450 kg · Exp Jun 8, 2026',          url: 'VendorInfo.html?q=BCH-4415' },

        // ── Vendors ──────────────────────────────────────────────────────
        { label: 'DHS Logistics',     sub: 'Vendor · VND-001 · Good Standing', url: 'VendorInfo.html?q=DHS+Logistics' },
        { label: 'Arctic Bio Supply', sub: 'Vendor · VND-002 · Good Standing', url: 'VendorInfo.html?q=Arctic+Bio+Supply' },
        { label: 'MedTech Pharma',    sub: 'Vendor · VND-003 · Under Review',  url: 'VendorInfo.html?q=MedTech+Pharma' },
        { label: 'FreshChain Co.',    sub: 'Vendor · VND-004 · Good Standing', url: 'VendorInfo.html?q=FreshChain+Co.' },

        // ── Warehouses ───────────────────────────────────────────────────
        { label: 'WH-204', sub: 'Warehouse · Temperature Controlled · Operational', url: 'Warehousedetail.html?id=WH-204' },
        { label: 'WH-301', sub: 'Warehouse · Overflow · Monitoring',                url: 'Warehousedetail.html?id=WH-301' },
        { label: 'WH-108', sub: 'Warehouse · Temperature Controlled · Maintenance', url: 'Warehousedetail.html?id=WH-108' },
        { label: 'WH-221', sub: 'Warehouse · Overflow · Operational',               url: 'Warehousedetail.html?id=WH-221' },
        { label: 'WH-399', sub: 'Warehouse · Temperature Controlled · Monitoring',  url: 'Warehousedetail.html?id=WH-399' },

        // ── Clinics / Locations ──────────────────────────────────────────
        { label: 'Phoenix Distribution Hub',   sub: 'Clinic / Destination · OUT-40127 · Scheduled', url: 'WarehouseShipmentDetails.html?id=OUT-40127' },
        { label: 'San Diego Clinic Network',   sub: 'Clinic / Destination · OUT-40119 · In Transit', url: 'WarehouseShipmentDetails.html?id=OUT-40119' },
        { label: 'Las Vegas Medical Center',   sub: 'Clinic / Destination · OUT-40103 · Delivered',  url: 'WarehouseShipmentDetails.html?id=OUT-40103' },
        { label: 'Tucson Partner Warehouse',   sub: 'Clinic / Destination · OUT-40098 · Delayed',    url: 'WarehouseShipmentDetails.html?id=OUT-40098' },
        { label: 'Fresno Consolidation Site',  sub: 'Clinic / Origin · IN-87214 · Scheduled',        url: 'WarehouseShipmentDetails.html?id=IN-87214' },
        { label: 'Sacramento Cold Chain Node', sub: 'Clinic / Origin · IN-87201 · Arrived',          url: 'WarehouseShipmentDetails.html?id=IN-87201' },
        { label: 'Reno Supply Facility',       sub: 'Clinic / Origin · IN-87188 · In Transit',       url: 'WarehouseShipmentDetails.html?id=IN-87188' },
        { label: 'Boise Transfer Site',        sub: 'Clinic / Origin · IN-87180 · Delivered',        url: 'WarehouseShipmentDetails.html?id=IN-87180' },

        // ── Lots ─────────────────────────────────────────────────────────
        { label: 'LOT-001', sub: 'Lot · Zone A3 · DHS Logistics BCH-0942',          url: 'CustodyEvent.html?q=LOT-001' },
        { label: 'LOT-002', sub: 'Lot · Truck TRK-204 · DHS Logistics BCH-0942',    url: 'CustodyEvent.html?q=LOT-002' },
        { label: 'LOT-003', sub: 'Lot · Delivered · DHS Logistics BCH-0942',        url: 'CustodyEvent.html?q=LOT-003' },
        { label: 'LOT-011', sub: 'Lot · Zone B1 · DHS Logistics BCH-0975',          url: 'CustodyEvent.html?q=LOT-011' },
        { label: 'LOT-012', sub: 'Lot · Zone B1 · DHS Logistics BCH-0975',          url: 'CustodyEvent.html?q=LOT-012' },
        { label: 'LOT-021', sub: 'Lot · Zone C3 Hold · DHS Logistics BCH-1018',     url: 'CustodyEvent.html?q=LOT-021' },
        { label: 'LOT-022', sub: 'Lot · Zone C3 Hold · DHS Logistics BCH-1018',     url: 'CustodyEvent.html?q=LOT-022' },
        { label: 'LOT-031', sub: 'Lot · Zone D1 Freezer · Arctic Bio BCH-2201',     url: 'CustodyEvent.html?q=LOT-031' },
        { label: 'LOT-032', sub: 'Lot · Truck TRK-311 · Arctic Bio BCH-2201',       url: 'CustodyEvent.html?q=LOT-032' },
        { label: 'LOT-033', sub: 'Lot · Delivered · Arctic Bio BCH-2201',           url: 'CustodyEvent.html?q=LOT-033' },
        { label: 'LOT-034', sub: 'Lot · Zone D1 Freezer · Arctic Bio BCH-2201',     url: 'CustodyEvent.html?q=LOT-034' },
        { label: 'LOT-041', sub: 'Lot · Zone D2 Freezer · Arctic Bio BCH-2215',     url: 'CustodyEvent.html?q=LOT-041' },
        { label: 'LOT-051', sub: 'Lot · Delivered · MedTech Pharma BCH-3301',       url: 'CustodyEvent.html?q=LOT-051' },
        { label: 'LOT-052', sub: 'Lot · Delivered · MedTech Pharma BCH-3301',       url: 'CustodyEvent.html?q=LOT-052' },
        { label: 'LOT-053', sub: 'Lot · Truck TRK-408 · MedTech Pharma BCH-3301',   url: 'CustodyEvent.html?q=LOT-053' },
        { label: 'LOT-061', sub: 'Lot · Zone A1 · MedTech Pharma BCH-3318',         url: 'CustodyEvent.html?q=LOT-061' },
        { label: 'LOT-062', sub: 'Lot · Zone A1 · MedTech Pharma BCH-3318',         url: 'CustodyEvent.html?q=LOT-062' },
        { label: 'LOT-071', sub: 'Lot · Zone E2 Cold · FreshChain BCH-4401',        url: 'CustodyEvent.html?q=LOT-071' },
        { label: 'LOT-072', sub: 'Lot · Truck TRK-512 · FreshChain BCH-4401',       url: 'CustodyEvent.html?q=LOT-072' },
        { label: 'LOT-073', sub: 'Lot · Zone E2 Cold · FreshChain BCH-4401',        url: 'CustodyEvent.html?q=LOT-073' },
        { label: 'LOT-081', sub: 'Lot · Delivered · FreshChain BCH-4415',           url: 'CustodyEvent.html?q=LOT-081' },
        { label: 'LOT-082', sub: 'Lot · Delivered · FreshChain BCH-4415',           url: 'CustodyEvent.html?q=LOT-082' }
    ];

    var input = document.querySelector('.search-bar');
    if (!input) return;

    // Wrap input in a positioned container
    var wrapper = document.createElement('div');
    wrapper.className = 'search-wrapper';
    input.parentNode.insertBefore(wrapper, input);
    wrapper.appendChild(input);

    // Create results dropdown
    var dropdown = document.createElement('div');
    dropdown.className = 'search-results';
    wrapper.appendChild(dropdown);

    input.placeholder = '\uD83D\uDD0D Search shipment, batch, vendor, clinic\u2026';

    input.addEventListener('input', function () {
        var q = this.value.trim().toLowerCase();
        if (!q || q.length < 2) {
            dropdown.classList.remove('open');
            return;
        }

        var hits = INDEX.filter(function (item) {
            return item.label.toLowerCase().indexOf(q) !== -1 ||
                   item.sub.toLowerCase().indexOf(q) !== -1;
        }).slice(0, 8);

        if (!hits.length) {
            dropdown.innerHTML = '<div class="search-no-results">No results found</div>';
        } else {
            dropdown.innerHTML = hits.map(function (item) {
                return '<div class="search-result-item" data-url="' + item.url + '">' +
                       '<div class="search-result-label">' + item.label + '</div>' +
                       '<div class="search-result-sub">'   + item.sub   + '</div>' +
                       '</div>';
            }).join('');
            dropdown.querySelectorAll('.search-result-item').forEach(function (el) {
                el.addEventListener('mousedown', function (e) {
                    e.preventDefault();
                    window.location.href = this.getAttribute('data-url');
                });
            });
        }
        dropdown.classList.add('open');
    });

    input.addEventListener('blur', function () {
        setTimeout(function () { dropdown.classList.remove('open'); }, 150);
    });

    input.addEventListener('keydown', function (e) {
        if (e.key === 'Escape') {
            dropdown.classList.remove('open');
            this.value = '';
        }
    });
}());
