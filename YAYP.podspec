Pod::Spec.new do |spec|
  spec.name         = 'YAYP'
  spec.version      = '0.2.0'
  spec.license      = { :type => 'MIT' }
  spec.homepage     = 'https://github.com/akkyie/YouTubePlayer'
  spec.authors      = { 'Akio Yasui' => 'akkyie@gmail.com' }
  spec.summary      = 'Yet Another YouTube Player.'
  spec.source       = { :git => 'https://github.com/akkyie/YouTubePlayer.git', :tag => '0.2.0' }
  spec.module_name  = 'YouTubePlayer'

  spec.ios.deployment_target  = '10.0'

  spec.source_files    = 'YouTubePlayer/*.{h,swift}'
  spec.resources       = 'YouTubePlayer/Template/*'

  spec.framework      = 'AVFoundation'
  spec.ios.framework  = 'UIKit'
end
