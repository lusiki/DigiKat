local page_meta = nil

local months = {
  "siječnja", "veljače", "ožujka", "travnja", "svibnja", "lipnja",
  "srpnja", "kolovoza", "rujna", "listopada", "studenoga", "prosinca"
}

local status_classes = {
  ["Radni prikaz"] = "working",
  ["Preliminarno"] = "preliminary",
  ["Ažurira se"] = "updating",
  ["Stabilno izdanje"] = "stable",
  ["Arhivirano"] = "archived",
  ["Working view"] = "working",
  ["Preliminary"] = "preliminary",
  ["Updated"] = "updating",
  ["Stable edition"] = "stable",
  ["Archived"] = "archived"
}

local function meta_string(value)
  if value == nil then return nil end
  local text = pandoc.utils.stringify(value)
  if text == "" then return nil end
  return text
end

local function meta_true(value)
  return value ~= nil and pandoc.utils.stringify(value) == "true"
end

local function html_escape(value)
  return value:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
end

local function display_date(value, language)
  if not value then return nil end
  local year, month, day = value:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
  month = tonumber(month)
  day = tonumber(day)
  if not year or not month or not day or not months[month] then return value end
  if language == "en" then return string.format("%s-%02d-%02d", year, month, day) end
  return string.format("%d. %s %s.", day, months[month], year)
end

function Meta(meta)
  page_meta = {
    show = meta_true(meta["show-freshness"]),
    language = meta_string(meta.lang) or "hr",
    published = meta_string(meta.date),
    modified = meta_string(meta["date-modified"]),
    cutoff = meta_string(meta["data-cutoff"]),
    status = meta_string(meta.status)
  }
  return meta
end

function Pandoc(doc)
  if not page_meta or not page_meta.show then return doc end
  if not page_meta.status or not status_classes[page_meta.status] then
    error("show-freshness requires one ratified DigiKat status value")
  end

  local items = {}
  local function add_item(label, value, is_status)
    if not value then return end
    if is_status then
      table.insert(items, string.format(
        '<span class="freshness-strip__item"><span class="freshness-strip__label">%s</span><span class="status status--%s">%s</span></span>',
        label, status_classes[value], html_escape(value)
      ))
    else
      table.insert(items, string.format(
        '<span class="freshness-strip__item"><span class="freshness-strip__label">%s</span><span class="freshness-strip__value">%s</span></span>',
        label, html_escape(display_date(value, page_meta.language))
      ))
    end
  end

  local labels = page_meta.language == "en" and {
    published = "Published", modified = "Updated", cutoff = "Data through", status = "Status",
    aria = "Page freshness and status"
  } or {
    published = "Objavljeno", modified = "Ažurirano", cutoff = "Podaci zaključno s", status = "Status",
    aria = "Svježina i status stranice"
  }
  add_item(labels.published, page_meta.published, false)
  add_item(labels.modified, page_meta.modified, false)
  add_item(labels.cutoff, page_meta.cutoff, false)
  add_item(labels.status, page_meta.status, true)

  local strip = '<div class="freshness-strip" aria-label="' .. labels.aria .. '">' ..
    table.concat(items, "") .. '</div>'
  table.insert(doc.blocks, 1, pandoc.RawBlock("html", strip))
  return doc
end
