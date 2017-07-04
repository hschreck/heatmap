require 'json'
require 'net/http'
require 'uri'
#get machine serial number
serial = `sudo dmidecode -t 1 | grep Serial | sed 's/.*: //g'`.chomp

#Request image from server and set image to response
uri = URI.parse("http://192.168.50.2:3001/api/image")
request = Net::HTTP::Post.new(uri)
request.set_form_data(
	"serial" => serial.downcase,
)
puts serial
puts request
req_options = {
  use_ssl: uri.scheme == "https",
}
begin
	response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
  		http.request(request)
	end
	response = JSON.parse(response.body)
	if response["error"]
		puts response["error"]
		abort
	end
	image = response["image-name"]
	puts image
rescue
	retry
end
system("sudo ocs-sr -ius -icrc -irhr -e1 auto -e2 -j2 -scr -icds -p command restoredisk #{image} sda")

if system("sudo mkdir /media/winos")
	if system("sudo mount -t ntfs -o remove_hiberfile /dev/sda3 /media/winos")
		if system("sudo cp /home/er2/SCS/* /media/winos/SCS\\ Additional\\ Software/")
			puts "Copied scripts successfully!"
		end
	system("sudo umount /dev/sda3")
	end
end
#Debugging, mostly
puts serial
puts image

system("reboot")
