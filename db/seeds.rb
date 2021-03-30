User.create(username: 'admin', password: 'admin', is_admin: true, avatar: {io: File.open('Steven_Riggs_photo.jpg'), filename: 'Steven_Riggs_photo.jpg', content_type: 'application/jpeg'})

10.times do |index|
  user = User.create(username: "user#{index}", password: 'password', avatar: {io: File.open('Steven_Riggs_photo.jpg'), filename: 'Steven_Riggs_avatar', content_type: 'application/jpeg'})
  puts user
end

15.times do |index|
  stored_image = StoredImage.create(image: {io: File.open('Steven_Riggs_photo.jpg'), filename: 'Steven_Riggs_photo.jpg', content_type: 'application/jpeg'})
  puts stored_image
end

User.all.sample(6).each do |user|
  (Random.rand(2) + 3).times do
    user.images.attach(io: File.open('laura-ollier-1XnXnRdzGbk-unsplash.jpg'), filename: 'laura-ollier-1XnXnRdzGbk-unsplash.jpg', content_type: 'application/jpeg')
  end
end

StoredImage.all.sample(7).each do |stored_image|
  stored_image.verified = true
  stored_image.save
end
