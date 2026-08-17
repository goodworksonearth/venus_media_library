// VenusMediaLibrary picker — dependency-free vanilla controller.
//
// Wiring (all via delegated events, no framework required):
//   [data-ml-open][data-ml-target][data-ml-src]  open the modal for a field
//   [data-ml-close]                               close the modal
//   .ml-tile[data-ml-url][data-ml-signed-id]      choose an image
//   input[data-ml-upload]                         upload a new image
//
// Works alongside Turbo if present, but does not require it.
(function () {
  "use strict";

  var MODAL_ID = "ml-modal";
  var FRAME_ID = "venus_media_library_picker";
  var activeTargetId = null;

  function modal() { return document.getElementById(MODAL_ID); }
  function frame() { return document.getElementById(FRAME_ID); }

  function csrfToken() {
    var el = document.querySelector('meta[name="csrf-token"]');
    return el ? el.getAttribute("content") : null;
  }

  function openModal(targetId, src) {
    var m = modal();
    if (!m) return;
    activeTargetId = targetId;
    m.hidden = false;
    m.setAttribute("aria-hidden", "false");
    m.classList.add("ml-modal--open");
    loadFrame(src);
  }

  function closeModal() {
    var m = modal();
    if (!m) return;
    m.hidden = true;
    m.setAttribute("aria-hidden", "true");
    m.classList.remove("ml-modal--open");
    activeTargetId = null;
  }

  function loadFrame(src) {
    var f = frame();
    if (!f || !src) return;
    // If Turbo is present, let it drive the frame; otherwise fetch manually.
    if (window.Turbo && f.tagName.toLowerCase() === "turbo-frame") {
      f.setAttribute("src", src);
      return;
    }
    fetch(src, { headers: { "Accept": "text/html", "X-Requested-With": "XMLHttpRequest" } })
      .then(function (r) { return r.text(); })
      .then(function (html) {
        var doc = new DOMParser().parseFromString(html, "text/html");
        var incoming = doc.getElementById(FRAME_ID);
        f.innerHTML = incoming ? incoming.innerHTML : html;
      })
      .catch(function () { f.innerHTML = '<p class="ml-empty">Could not load the library.</p>'; });
  }

  function chooseTile(tile) {
    if (!activeTargetId) { closeModal(); return; }
    var url = tile.getAttribute("data-ml-url");
    var signedId = tile.getAttribute("data-ml-signed-id");

    var input = document.getElementById(activeTargetId);
    if (input) {
      input.value = url;
      input.dispatchEvent(new Event("input", { bubbles: true }));
      input.dispatchEvent(new Event("change", { bubbles: true }));
    }
    var hidden = document.querySelector('[data-ml-signed-id-for="' + activeTargetId + '"]');
    if (hidden) {
      hidden.value = signedId;
      // Attach mode ships the hidden field disabled so an empty value can't
      // detach the current file; enable it now that a signed_id is set.
      hidden.disabled = false;
    }

    closeModal();
  }

  function upload(fileInput) {
    var file = fileInput.files && fileInput.files[0];
    if (!file) return;

    var status = document.querySelector("[data-ml-status]");
    if (status) status.textContent = "Uploading…";

    var form = new FormData();
    form.append("file", file);
    var share = document.querySelector("[data-ml-community-share]");
    form.append("community_shared", share && share.checked ? "1" : "0");

    var headers = { "Accept": "application/json" };
    var token = csrfToken();
    if (token) headers["X-CSRF-Token"] = token;

    fetch(uploadUrl(), { method: "POST", body: form, headers: headers, credentials: "same-origin" })
      .then(function (r) {
        if (!r.ok) throw new Error("Upload failed");
        return r.json();
      })
      .then(function (image) {
        if (status) status.textContent = "Uploaded " + image.filename;
        prependTile(image);
      })
      .catch(function () { if (status) status.textContent = "Upload failed."; });
  }

  // Derives the images upload URL from the picker frame src (…/picker → …/images).
  function uploadUrl() {
    var f = document.querySelector("[data-ml-target]");
    var base = f ? f.getAttribute("data-ml-src") : null;
    if (base) return base.replace(/\/picker(\?.*)?$/, "/images");
    return "images";
  }

  function prependTile(image) {
    var grid = document.querySelector("[data-ml-grid]");
    if (!grid) return;
    // Build with DOM methods (not innerHTML): filenames are user-controlled, so
    // assigning them as properties/attributes avoids any HTML injection.
    var btn = document.createElement("button");
    btn.type = "button";
    btn.className = "ml-tile";
    btn.setAttribute("data-ml-signed-id", image.signed_id);
    btn.setAttribute("data-ml-url", image.url);
    btn.setAttribute("data-ml-filename", image.filename);
    btn.title = image.filename;

    var img = document.createElement("img");
    img.src = image.thumb_url;
    img.alt = image.filename;
    img.loading = "lazy";

    var name = document.createElement("span");
    name.className = "ml-tile__name";
    name.textContent = image.filename;

    btn.appendChild(img);
    btn.appendChild(name);
    grid.insertBefore(btn, grid.firstChild);
  }

  document.addEventListener("click", function (e) {
    var opener = e.target.closest("[data-ml-open]");
    if (opener) {
      e.preventDefault();
      openModal(opener.getAttribute("data-ml-target"), opener.getAttribute("data-ml-src"));
      return;
    }
    if (e.target.closest("[data-ml-close]")) {
      e.preventDefault();
      closeModal();
      return;
    }
    var tile = e.target.closest(".ml-tile");
    if (tile && tile.closest("#" + MODAL_ID)) {
      e.preventDefault();
      chooseTile(tile);
    }
  });

  document.addEventListener("change", function (e) {
    if (e.target.matches("[data-ml-upload]")) upload(e.target);
  });

  document.addEventListener("keydown", function (e) {
    if (e.key === "Escape") closeModal();
  });
})();
