function Image(image)
  image.attributes.loading = image.attributes.loading or "lazy"
  image.attributes.decoding = image.attributes.decoding or "async"
  return image
end
