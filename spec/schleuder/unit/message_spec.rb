require "spec_helper"

describe Mail::Message do
  it "doesn't change the order of mime-parts" do
    text_part = Mail::Part.new
    text_part.body = "This is text"
    image_part = Mail::Part.new
    image_part.content_type = 'image/png'
    image_part.content_disposition = 'attachment; filename=spec.png'
    message = Mail.new
    message.parts << image_part
    message.parts << text_part

    # This triggers the sorting.
    message.to_s

    expect(message.parts.first.mime_type).to eql('image/png')
    expect(message.parts.last.mime_type).to eql('text/plain')
  end
end

