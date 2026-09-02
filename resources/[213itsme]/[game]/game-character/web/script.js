const selectorData = {
  father: [
    "Adrian", "Alex", "Andrew", "Angel", "Anthony", "Benjamin", "Claude", "Daniel",
    "Diego", "Ethan", "Evan", "Gabriel", "Isaac", "John", "Joshua", "Juan",
    "Kevin", "Louis", "Michael", "Niko", "Noah", "Samuel", "Santiago", "Vincent"
  ],
  mother: [
    "Amelia", "Ashley", "Audrey", "Ava", "Brianna", "Camila", "Hannah", "Isabella",
    "Misty", "Natalie", "Nicole", "Olivia", "Sophia", "Zoe"
  ],
  hair: ["Coupe 0", "Coupe 1", "Coupe 2", "Coupe 3", "Coupe 4", "Coupe 5", "Coupe 6", "Coupe 7"],
  eyebrows: ["Aucun", "Fin", "Naturel", "Épais", "Arqué", "Court", "Dense"],
  beard: ["Aucune", "Bouc", "Barbe 3 jours", "Collier", "Complète", "Moustache", "Balbo"],
  chesthair: ["Aucun", "Léger", "Moyen", "Dense", "Torse 1", "Torse 2", "Torse 3"],
  blemishes: ["Aucun", "Type 1", "Type 2", "Type 3", "Type 4", "Type 5"],
  aging: ["Aucun", "Léger", "Moyen", "Marqué", "Type 1", "Type 2"],
  complexion: ["Aucun", "Rosé", "Chaud", "Froid", "Fatigué", "Pâle"],
  sunDamage: ["Aucun", "Léger", "Moyen", "Fort", "Type 1", "Type 2"],
  moles: ["Aucun", "Léger", "Moyen", "Dense", "Type 1", "Type 2"],
  bodyBlemish: ["Aucun", "Type 1", "Type 2", "Type 3", "Type 4"],
  bodyBlemish2: ["Aucun", "Type 1", "Type 2", "Type 3", "Type 4"],
  makeup: ["Aucun", "Style 1", "Style 2", "Style 3", "Style 4", "Style 5"],
  lipstick: ["Aucun", "Rouge 1", "Rouge 2", "Rouge 3", "Rouge 4", "Rouge 5"],
  blush: ["Aucun", "Blush 1", "Blush 2", "Blush 3", "Blush 4", "Blush 5"]
};

const creatorState = {
  sex: 0,
  dad: 0,
  mom: 0,
  face_md_weight: 50,
  skin_md_weight: 50
};

function postNui(eventName, data = {}) {
  fetch(`https://${GetParentResourceName()}/${eventName}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json"
    },
    body: JSON.stringify(data)
  });
}

function sendCreatorUpdate(key, value) {
  postNui("creator:update", { key, value });
}

function gameToSkinValue(value) {
  return Math.round((Number(value) - 50) * 2);
}

function updateSelectorImage(selectorElement, selectedName) {
  const imageTargetId = selectorElement.dataset.imageTarget;
  const imageFolder = selectorElement.dataset.imageFolder;
  if (!imageTargetId || !imageFolder) return;

  const imageElement = document.getElementById(imageTargetId);
  if (!imageElement) return;

  imageElement.src = `${imageFolder}/${selectedName}.png`;
  imageElement.alt = selectedName;
}

function updateSliderFill(slider) {
  const min = Number(slider.min) || 0;
  const max = Number(slider.max) || 100;
  const value = Number(slider.value) || 0;
  const percent = ((value - min) * 100) / (max - min);

  slider.style.background = `linear-gradient(90deg, var(--blue) 0 ${percent}%, rgba(255, 255, 255, 0.14) ${percent}% 100%)`;

  const valueLabel = slider.parentElement?.querySelector(".slider-value")
    || slider.closest(".trait-slider-block")?.querySelector(".slider-value")
    || slider.closest(".slider-block")?.querySelector(".slider-value")
    || slider.closest(".panel-section")?.querySelector(".slider-value");

  if (valueLabel) {
    valueLabel.textContent = `${value}%`;
  }
}

function initGenderTabs() {
  const tabs = document.querySelectorAll(".gender-tabs .tab:not(.disabled)");

  tabs.forEach((tab) => {
    tab.addEventListener("click", () => {
      tabs.forEach((item) => item.classList.remove("active"));
      tab.classList.add("active");

      const sex = Number(tab.dataset.sex || 0);
      creatorState.sex = sex;
      sendCreatorUpdate("sex", sex);
    });
  });
}

function initSelectors() {
  document.querySelectorAll("[data-selector]").forEach((selectorElement) => {
    const key = selectorElement.dataset.selector;
    const values = selectorData[key];

    if (!values || !values.length) return;

    let currentIndex = 0;

    const leftArrow = selectorElement.querySelector(".arrow-left");
    const rightArrow = selectorElement.querySelector(".arrow-right");
    const label = selectorElement.querySelector(".selector-name");

    function onChange() {
      if (key === "father") sendCreatorUpdate("dad", currentIndex);
      if (key === "mother") sendCreatorUpdate("mom", currentIndex);
      if (key === "hair") sendCreatorUpdate("hair_1", currentIndex);
      if (key === "eyebrows") sendCreatorUpdate("eyebrows_1", currentIndex);
      if (key === "beard") sendCreatorUpdate("beard_1", currentIndex);
      if (key === "chesthair") sendCreatorUpdate("chest_1", currentIndex);
      if (key === "blemishes") sendCreatorUpdate("blemishes_1", currentIndex);
      if (key === "aging") sendCreatorUpdate("age_1", currentIndex);
      if (key === "complexion") sendCreatorUpdate("complexion_1", currentIndex);
      if (key === "sunDamage") sendCreatorUpdate("sun_1", currentIndex);
      if (key === "moles") sendCreatorUpdate("moles_1", currentIndex);
      if (key === "bodyBlemish") sendCreatorUpdate("bodyb_1", currentIndex);
      if (key === "bodyBlemish2") sendCreatorUpdate("bodyb_3", currentIndex);
      if (key === "makeup") sendCreatorUpdate("makeup_1", currentIndex);
      if (key === "lipstick") sendCreatorUpdate("lipstick_1", currentIndex);
      if (key === "blush") sendCreatorUpdate("blush_1", currentIndex);
    }

    function refreshSelector() {
      const currentValue = values[currentIndex];
      if (label) label.textContent = currentValue;
      updateSelectorImage(selectorElement, currentValue);
      onChange();
    }

    refreshSelector();

    if (leftArrow) {
      leftArrow.addEventListener("click", () => {
        currentIndex = (currentIndex - 1 + values.length) % values.length;
        refreshSelector();
      });
    }

    if (rightArrow) {
      rightArrow.addEventListener("click", () => {
        currentIndex = (currentIndex + 1) % values.length;
        refreshSelector();
      });
    }
  });
}

function bindSkinSliders() {
  document.querySelectorAll(".game-slider[data-skin-key]").forEach((slider) => {
    updateSliderFill(slider);

    slider.addEventListener("input", () => {
      updateSliderFill(slider);
      const key = slider.dataset.skinKey;
      const value = Number(slider.value);

      creatorState[key] = value;
      sendCreatorUpdate(key, value);

      if (key === "skin_md_weight") {
        syncToneRows(value);
      }
    });
  });
}

function setSliderValue(slider, value, shouldSend = true) {
  if (!slider) return;

  slider.value = value;
  updateSliderFill(slider);

  if (shouldSend && slider.dataset.skinKey) {
    creatorState[slider.dataset.skinKey] = Number(value);
    sendCreatorUpdate(slider.dataset.skinKey, Number(value));
  }
}

function syncToneRows(value) {
  const toneRows = document.querySelectorAll(".panel-page-body .tone-row");
  const steps = [0, 20, 40, 60, 80, 100];

  let closestIndex = 0;
  let closestDiff = Infinity;

  steps.forEach((step, index) => {
    const diff = Math.abs(step - Number(value));
    if (diff < closestDiff) {
      closestDiff = diff;
      closestIndex = index;
    }
  });

  toneRows.forEach((row) => {
    const buttons = row.querySelectorAll(".tone");
    buttons.forEach((btn, index) => {
      btn.classList.toggle("selected", index === closestIndex);
    });
  });
}

function bindToneRows() {
  const toneRows = document.querySelectorAll(".panel-page-body .tone-row");
  const skinMixSlider = document.querySelector('.panel-page-body .game-slider[data-skin-key="skin_md_weight"]');
  const presets = [0, 20, 40, 60, 80, 100];

  toneRows.forEach((row) => {
    const buttons = row.querySelectorAll(".tone");

    buttons.forEach((button, index) => {
      button.addEventListener("click", () => {
        buttons.forEach((btn) => btn.classList.remove("selected"));
        button.classList.add("selected");

        const value = presets[index] ?? 50;

        creatorState.skin_md_weight = value;
        setSliderValue(skinMixSlider, value, true);
        syncToneRows(value);
      });
    });
  });

  if (skinMixSlider) {
    syncToneRows(Number(skinMixSlider.value || 50));
  }
}

function bindTraitSliders() {
  document.querySelectorAll(".game-slider[data-trait-key]").forEach((slider) => {
    updateSliderFill(slider);

    slider.addEventListener("input", () => {
      updateSliderFill(slider);
      const key = slider.dataset.traitKey;
      if (!key || key === "eye_opening") return;
      sendCreatorUpdate(key, gameToSkinValue(slider.value));
    });
  });
}

function bindOpacitySliders() {
  document.querySelectorAll(".panel-section").forEach((section) => {
    const title = section.querySelector(".panel-title")?.textContent?.trim()?.toLowerCase();
    const sliders = section.querySelectorAll(".game-slider:not([data-skin-key]):not([data-trait-key])");
    if (!sliders.length) return;

    sliders.forEach((slider) => {
      updateSliderFill(slider);

      slider.addEventListener("input", () => {
        updateSliderFill(slider);
        const value = Number(slider.value);

        if (title === "sourcils") sendCreatorUpdate("eyebrows_2", value);
        if (title === "barbe") sendCreatorUpdate("beard_2", value);
        if (title === "poil torse") sendCreatorUpdate("chest_2", value);
        if (title === "imperfections") sendCreatorUpdate("blemishes_2", value);
        if (title === "vieillissement") sendCreatorUpdate("age_2", value);
        if (title === "teint") sendCreatorUpdate("complexion_2", value);
        if (title === "dommages du soleil") sendCreatorUpdate("sun_2", value);
        if (title === "grains de beauté") sendCreatorUpdate("moles_2", value);
        if (title === "imperfection du corps") sendCreatorUpdate("bodyb_2", value);
        if (title === "imperfection du corps 2") sendCreatorUpdate("bodyb_4", value);
        if (title === "maquillage") sendCreatorUpdate("makeup_2", value);
        if (title === "rouge à lèvres") sendCreatorUpdate("lipstick_2", value);
        if (title === "blush") sendCreatorUpdate("blush_2", value);
      });
    });
  });
}

function initSwatchGroups() {
  document.querySelectorAll("[data-swatch-group]").forEach((group) => {
    const swatches = group.querySelectorAll(".color-swatch");

    swatches.forEach((swatch, index) => {
      swatch.addEventListener("click", () => {
        swatches.forEach((item) => item.classList.remove("is-selected"));
        swatch.classList.add("is-selected");

        const panelSection = swatch.closest(".panel-section");
        const title = panelSection?.querySelector(".panel-title")?.textContent?.trim()?.toLowerCase() || "";
        const groupLabel = swatch.closest(".palette-group")?.querySelector(".group-label")?.textContent?.trim()?.toLowerCase() || "";

        if (title === "couleur des yeux") {
          sendCreatorUpdate("eye_color", index);
        }

        if (title === "cheveux" && groupLabel === "couleur") {
          sendCreatorUpdate("hair_color_1", index);
        }

        if (title === "cheveux" && groupLabel === "couleur secondaire") {
          sendCreatorUpdate("hair_color_2", index);
        }

        if (title === "sourcils") {
          sendCreatorUpdate("eyebrows_3", index);
          sendCreatorUpdate("eyebrows_4", index);
        }

        if (title === "barbe") {
          sendCreatorUpdate("beard_3", index);
          sendCreatorUpdate("beard_4", index);
        }

        if (title === "poil torse") {
          sendCreatorUpdate("chest_3", index);
          sendCreatorUpdate("chest_4", index);
        }

        if (title === "maquillage") {
          sendCreatorUpdate("makeup_3", index);
          sendCreatorUpdate("makeup_4", index);
        }

        if (title === "rouge à lèvres") {
          sendCreatorUpdate("lipstick_3", index);
          sendCreatorUpdate("lipstick_4", index);
        }

        if (title === "blush") {
          sendCreatorUpdate("blush_3", index);
        }
      });
    });
  });
}

function initPageNavigation() {
  const pageButtons = document.querySelectorAll("[data-page-target]");
  const pages = document.querySelectorAll(".panel-page");

  pageButtons.forEach((button) => {
    button.addEventListener("click", () => {
      const target = button.dataset.pageTarget;

      pages.forEach((page) => {
        page.classList.toggle("is-active", page.dataset.page === target);
      });

      pageButtons.forEach((item) => item.classList.remove("active"));
      button.classList.add("active");
    });
  });
}

function initCustomPanelScroll(viewportId, thumbId) {
  const viewport = document.getElementById(viewportId);
  const thumb = document.getElementById(thumbId);
  if (!viewport || !thumb) return;

  const track = thumb.parentElement;

  function refresh() {
    const scrollHeight = viewport.scrollHeight;
    const clientHeight = viewport.clientHeight;
    const trackHeight = track.clientHeight;

    if (scrollHeight <= clientHeight) {
      thumb.style.height = `${trackHeight}px`;
      thumb.style.transform = `translateY(0px)`;
      return;
    }

    const thumbHeight = Math.max((clientHeight / scrollHeight) * trackHeight, 60);
    const maxThumbTop = trackHeight - thumbHeight;
    const maxScrollTop = scrollHeight - clientHeight;
    const thumbTop = (viewport.scrollTop / maxScrollTop) * maxThumbTop;

    thumb.style.height = `${thumbHeight}px`;
    thumb.style.transform = `translateY(${thumbTop}px)`;
  }

  viewport.addEventListener("scroll", refresh);
  window.addEventListener("resize", refresh);

  let isDragging = false;
  let startY = 0;
  let startScrollTop = 0;

  thumb.addEventListener("mousedown", (event) => {
    isDragging = true;
    startY = event.clientY;
    startScrollTop = viewport.scrollTop;
    document.body.style.userSelect = "none";
  });

  window.addEventListener("mousemove", (event) => {
    if (!isDragging) return;

    const scrollHeight = viewport.scrollHeight;
    const clientHeight = viewport.clientHeight;
    const trackHeight = track.clientHeight;
    const thumbHeight = thumb.clientHeight;
    const maxScrollTop = scrollHeight - clientHeight;
    const maxThumbTop = trackHeight - thumbHeight;
    const deltaY = event.clientY - startY;
    const scrollDelta = (deltaY / maxThumbTop) * maxScrollTop;

    viewport.scrollTop = startScrollTop + scrollDelta;
  });

  window.addEventListener("mouseup", () => {
    isDragging = false;
    document.body.style.userSelect = "";
  });

  refresh();
}

function initTopCameraSwitch() {
  const buttons = document.querySelectorAll(".top-center-switch .switch-item");

  buttons.forEach((button) => {
    button.addEventListener("click", () => {
      buttons.forEach((btn) => btn.classList.remove("active"));
      button.classList.add("active");

      const camMode = button.dataset.cam || "body";
      postNui("switchCamera", { mode: camMode });
    });
  });
}

window.addEventListener("message", (event) => {
  const data = event.data;

  if (data.action === "toggle") {
    document.body.style.display = data.show ? "block" : "none";

    if (data.show) {
      const bodyButton = document.querySelector('.top-center-switch .switch-item[data-cam="body"]');
      const buttons = document.querySelectorAll(".top-center-switch .switch-item");
      buttons.forEach((btn) => btn.classList.remove("active"));
      if (bodyButton) bodyButton.classList.add("active");
    }
  }
});

document.addEventListener("keydown", (event) => {
  if (event.key === "Escape") {
    postNui("close");
  }
});

function getFieldValue(selectors) {
  for (const selector of selectors) {
    const element = document.querySelector(selector);
    if (element) {
      return String(element.value || "").trim();
    }
  }
  return "";
}

function bindCreateCharacterButton() {
  const btn =
    document.getElementById("createCharacterBtn") ||
    Array.from(document.querySelectorAll("button")).find(b =>
      b.textContent.toLowerCase().includes("créer")
    );

  if (!btn) return;

  btn.addEventListener("click", () => {
    const firstname = document.getElementById("identityFirstname")?.value.trim() || "";
    const lastname = document.getElementById("identityLastname")?.value.trim() || "";

    const day = document.getElementById("identityBirthDay")?.value.trim() || "";
    const month = document.getElementById("identityBirthMonth")?.value.trim() || "";
    const year = document.getElementById("identityBirthYear")?.value.trim() || "";

    const height = document.getElementById("identityHeight")?.value.trim() || "180";

    if (!firstname || !lastname || !day || !month || !year) return;

    const dateofbirth = `${day.padStart(2, "0")}/${month.padStart(2, "0")}/${year}`;

    postNui("creator:submit", {
      firstname,
      lastname,
      dateofbirth,
      height
    });
  });
}

function formatDateInput(value) {
  const numbers = String(value).replace(/\D/g, "").slice(0, 8);

  if (numbers.length <= 2) return numbers;
  if (numbers.length <= 4) return `${numbers.slice(0, 2)}/${numbers.slice(2)}`;
  return `${numbers.slice(0, 2)}/${numbers.slice(2, 4)}/${numbers.slice(4, 8)}`;
}

function bindDateOfBirthInput() {
  const input =
    document.querySelector("#dateofbirth") ||
    document.querySelector("#birthdate") ||
    document.querySelector("input[name='dateofbirth']") ||
    document.querySelector("input[name='birthdate']") ||
    document.querySelector("[data-field='dateofbirth']");

  if (!input) return;

  input.setAttribute("maxlength", "10");
  input.setAttribute("placeholder", "JJ/MM/AAAA");

  input.addEventListener("input", () => {
    const start = input.selectionStart || 0;
    const before = input.value;
    input.value = formatDateInput(input.value);

    if (input.value.length > before.length && (input.value.length === 3 || input.value.length === 6)) {
      input.setSelectionRange(start + 1, start + 1);
    }
  });

  input.addEventListener("blur", () => {
    const value = input.value.trim();
    const match = value.match(/^(\d{2})\/(\d{2})\/(\d{4})$/);

    if (!match) return;

    const day = Number(match[1]);
    const month = Number(match[2]);
    const year = Number(match[3]);

    const date = new Date(year, month - 1, day);
    const isValid =
      date.getFullYear() === year &&
      date.getMonth() === month - 1 &&
      date.getDate() === day;

    if (!isValid) {
      input.value = "";
    }
  });
}

function getInputValue(selector) {
  const el = document.querySelector(selector);
  return el ? el.value.trim() : "";
}


document.addEventListener("DOMContentLoaded", () => {
  document.body.style.display = "none";

  initGenderTabs();
  initSelectors();
  initSwatchGroups();
  bindSkinSliders();
  bindTraitSliders();
  bindOpacitySliders();
  initPageNavigation();
  initTopCameraSwitch();
  bindToneRows();
  bindCreateCharacterButton();
  bindDateOfBirthInput();
  initCustomPanelScroll("hairPanelViewport", "hairPanelThumb");
  initCustomPanelScroll("facePanelViewport", "facePanelThumb");
  initCustomPanelScroll("traitsPanelViewport", "traitsPanelThumb");
  initCustomPanelScroll("makeupPanelViewport", "makeupPanelThumb");
});