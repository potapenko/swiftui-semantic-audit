(() => {
  "use strict";

  document.documentElement.classList.add("js");

  const menuButton = document.querySelector(".menu-toggle");
  const navigation = document.querySelector(".site-nav");

  const closeNavigation = () => {
    if (!menuButton || !navigation) return;
    menuButton.setAttribute("aria-expanded", "false");
    navigation.classList.remove("is-open");
  };

  if (menuButton && navigation) {
    menuButton.addEventListener("click", () => {
      const shouldOpen = menuButton.getAttribute("aria-expanded") !== "true";
      menuButton.setAttribute("aria-expanded", String(shouldOpen));
      navigation.classList.toggle("is-open", shouldOpen);
    });

    navigation.addEventListener("click", (event) => {
      if (event.target.closest("a")) closeNavigation();
    });

    document.addEventListener("keydown", (event) => {
      if (event.key === "Escape" && menuButton.getAttribute("aria-expanded") === "true") {
        closeNavigation();
        menuButton.focus();
      }
    });
  }

  const fallbackCopy = (text) => {
    const textarea = document.createElement("textarea");
    textarea.value = text;
    textarea.setAttribute("readonly", "");
    textarea.style.position = "fixed";
    textarea.style.opacity = "0";
    document.body.appendChild(textarea);
    textarea.select();
    const copied = document.execCommand("copy");
    textarea.remove();
    if (!copied) throw new Error("Copy command was rejected");
  };

  const copyText = async (text) => {
    if (navigator.clipboard && window.isSecureContext) {
      await navigator.clipboard.writeText(text);
      return;
    }
    fallbackCopy(text);
  };

  document.querySelectorAll("[data-copy-target]").forEach((button) => {
    button.addEventListener("click", async () => {
      const target = document.getElementById(button.dataset.copyTarget);
      const statusId = button.getAttribute("aria-describedby");
      const status = statusId ? document.getElementById(statusId) : null;
      const label = button.querySelector("span");
      const icon = button.querySelector("img");
      const originalLabel = label ? label.textContent : "Copy";
      const originalIcon = icon ? icon.getAttribute("src") : "";

      if (!target) return;

      try {
        await copyText(target.textContent.trim());
        if (label) label.textContent = "Copied";
        if (icon) icon.setAttribute("src", "assets/icons/check.svg");
        if (status) status.textContent = "Copied to the clipboard.";

        window.setTimeout(() => {
          if (label) label.textContent = originalLabel;
          if (icon) icon.setAttribute("src", originalIcon);
          if (status) status.textContent = "";
        }, 2200);
      } catch (_error) {
        if (status) status.textContent = "Copy failed. Select the text and copy it manually.";
      }
    });
  });
})();
