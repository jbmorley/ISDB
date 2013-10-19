Pod::Spec.new do |s|

  s.name         = "ISDB"
  s.version      = "0.0.1"
  s.summary      = "Pluggable Objective-C cache framework"
  s.homepage     = "https://github.com/jbmorley/ISDB"
  s.license      = { :type => 'MIT', :file => 'LICENSE.md' }
  s.author       = { "Jason Barrie Morley" => "jason.morley@inseven.co.uk" }
  s.source       = { :git => "https://github.com/jbmorley/ISDB.git", :commit => "f151ef79d64d88b232a8c34013dad2a1349437a3" }

  s.source_files = 'Classes/*.{h,m}'

  s.requires_arc = true

  s.platform = :ios, "6.0", :osx, "10.8"

  s.dependency 'FMDB', '~> 2.0'
  s.dependency 'ISUtilities'

end
