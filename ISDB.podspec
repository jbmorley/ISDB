Pod::Spec.new do |s|

  s.name         = "ISCache"
  s.version      = "0.0.1"
  s.summary      = "Pluggable Objective-C cache framework"
  s.homepage     = "https://github.com/jbmorley/ISDB"
  s.license      = { :type => 'MIT', :file => 'LICENSE.md' }
  s.author       = { "Jason Barrie Morley" => "jason.morley@inseven.co.uk" }
  s.source       = { :git => "https://github.com/jbmorley/ISDB.git", :commit => "88793e4fe4a2787526e038952fb9f3bd1bd83d66" }

  s.source_files = 'Classes/*.{h,m}'

  s.requires_arc = true

  s.platform = :ios, "6.0", :osx, "10.8"

  s.dependency 'FMDB', '~> 2.0'
  s.dependency 'ISUtilities'

end
