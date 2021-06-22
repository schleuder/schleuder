require 'spec_helper'

describe Http do
  it 'uses a proxy if one is configured' do
    proxy_url = 'socks5h://localhost:9050'
    Conf.instance.config['http_proxy'] = proxy_url

    req = Http.send(:new_request, 'http://localhost/something')

    expect(req.options[:proxy]).to eql(proxy_url)

    Conf.instance.reload!
  end
end

