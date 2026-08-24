-- The PDF keeps level-one chapter openers. On the web the document title is the sole H1,
-- so chapters and their subsections move down one semantic level without changing the source.

local html_output = FORMAT:match("html") ~= nil

function Header(header)
  if html_output and header.level <= 3 then
    header.level = header.level + 1
  end
  return header
end

function Image(image)
  if html_output then
    image.attributes.loading = image.attributes.loading or "lazy"
    image.attributes.decoding = image.attributes.decoding or "async"
  else
    -- Responsive HTML attributes are physical dimensions to Typst. Remove them so the PDF keeps
    -- the report template's width-aware image layout instead of treating web pixels as page units.
    for _, key in ipairs({"loading", "decoding", "srcset", "sizes", "width", "height"}) do
      image.attributes[key] = nil
    end
  end
  return image
end
