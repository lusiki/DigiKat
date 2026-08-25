local function png_dimensions(contents)
  if not contents or #contents < 24 or contents:sub(1, 8) ~= "\137PNG\13\10\26\10" then
    return nil, nil
  end

  local function uint32(offset)
    local a, b, c, d = contents:byte(offset, offset + 3)
    return ((a * 256 + b) * 256 + c) * 256 + d
  end

  return uint32(17), uint32(21)
end

local function intrinsic_dimensions(source)
  local ok, mime_type, contents = pcall(pandoc.mediabag.fetch, source)
  if not ok or mime_type ~= "image/png" then
    return nil, nil
  end

  return png_dimensions(contents)
end

local function mobile_source_for(source)
  local label = source:match("/([^/]+)%-1%.png$")
  if not label then
    return nil
  end

  return "../../assets/images/maps/mobile/" .. label .. ".png"
end

function Image(image)
  image.attributes.loading = image.attributes.loading or "lazy"
  image.attributes.decoding = image.attributes.decoding or "async"

  if not image.attributes.width or not image.attributes.height then
    local width, height = intrinsic_dimensions(image.src)
    if width and height then
      image.attributes.width = image.attributes.width or tostring(width)
      image.attributes.height = image.attributes.height or tostring(height)
    end
  end

  local mobile_source = mobile_source_for(image.src)
  if mobile_source then
    local mobile_width, mobile_height = intrinsic_dimensions(mobile_source)
    if mobile_width and mobile_height then
      image.attributes["data-mobile-src"] = mobile_source
      image.attributes["data-mobile-width"] = tostring(mobile_width)
      image.attributes["data-mobile-height"] = tostring(mobile_height)
    end
  end

  return image
end
