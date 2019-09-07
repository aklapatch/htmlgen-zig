 # HTMLgen-zig
 A zig library for generating html documents.

 ## development plans
 Have a `htmldoc` object that holds an arraylist of `element` objects. This `htmldoc` object will have a `writeDoc` method that writes all the tags to a html document.

 A `element` object will have these fields:
 - A `tag_name` buffer that holds the tag name: e.g. `p` or `h1`
 -  A `content` buffer: holds what goes between the tags: e.g. `<tag>content</tag>`
 - A `attribute` object that holds the attribute name and its definition
- An arraylist called `inner_elements` that holds other elements inside this one

A `attribute` object with the following fields:
- A `name` buffer with the attribute name
- A `value` buffer with the attribute's value
 
