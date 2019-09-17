Pod::Spec.new do |s|
s.name         = "PolioPager"
s.version      = "2.0.8"
s.summary      = "PolioPager enables us to use PagerTabStrip like SNKRS."
s.license      = { :type => 'MIT', :file => 'LICENSE' }
s.homepage     = "https://github.com/yuigawada/PolioPager"
s.author       = { "YuigaWada" => "yuigawada@gmail.com" }
s.source       = { :git => "https://github.com/yuigawada/PolioPager.git", :tag => "#{s.version}" }
s.platform     = :ios, "11.0"
s.requires_arc = true
s.source_files = 'PolioPager/**/*.{swift,h}'
s.resources    = 'PolioPager/**/*.{xib,xcassets}'
s.swift_version = "5.0"
end