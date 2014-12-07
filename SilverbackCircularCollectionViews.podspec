#
# Be sure to run `pod lib lint SilverbackCircularCollectionViews.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "SilverbackCircularCollectionViews"
  s.version          = "0.1.0"
  s.summary          = "Circular Collection view Layout"
  s.homepage         = "https://github.com/cotkjaer/SilverbackCircularCollectionViews"
  # s.screenshots      = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "Christian Otkjær" => "christian.otkjaer@gmail.com" }
  s.source           = { :git => "https://github.com/cotkjaer/SilverbackCircularCollectionViews.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/cotkjaer'

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes'

  s.ios.exclude_files = 'Classes/osx'
  s.osx.exclude_files = 'Classes/ios'
end
