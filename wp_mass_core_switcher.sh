#!/bin/sh

arr=( $(find $pwd -path "*/wp-includes/*.php" -name "version.php" 2>/dev/null) )

for i in "${arr[@]}"; 
do 	
	if test "${string#*"/wp-includes/version.php"}" != "$i" && [[ "${i%/*/*}" != "." ]]
	then

		current_path="${i%/*/*}"
		current_path="/home${current_path#.}"
		wp_version=$( grep -s "wp_version =" ${i%/*/*}/wp-includes/version.php 2>/dev/null | awk '{print $3}' | sed "s/'//g" | sed "s/;//g")
		download_link="https://wordpress.org/wordpress-$wp_version.tar.gz"
		cores_path="/home/wordpress_cores"
		wp_includes_fresh="$current_path/wordpress-$wp_version/wordpress/wp-includes"
		wp_admin_fresh="$current_path/wordpress-$wp_version/wordpress/wp-admin"
		current_user=$(stat -c '%U' $current_path/wp-config.php)

		echo "Working on: $current_path at the moment. . ."

		if [ ! -s "$cores_path/wordpress-$wp_version.tar.gz" ] 
		then
			echo "Downloading cores. . ."
    		sudo wget -q $download_link -O "$cores_path/wordpress-$wp_version.tar.gz"
		fi

		if [ -s "$cores_path/wordpress-$wp_version.tar.gz" ] 
		then
			echo 
			# Create folder and extract WP Archive. . .
			if [ ! -d "$current_path/wordpress-$wp_version" ]; then
				mkdir "$current_path/wordpress-$wp_version"
				tar zxf "$cores_path/wordpress-$wp_version.tar.gz" -C "$current_path/wordpress-$wp_version/"
			fi

			# Switch wp-includes with fresh folder
			if [ -d "$wp_includes_fresh" ]; then
				sudo mv "$current_path/wp-includes" "$current_path/wordpress-$wp_version/o-wp-includes"
				sudo mv $wp_includes_fresh "$current_path/wp-includes"
				sudo chown -R $current_user:$current_user "$current_path/wp-includes"
				echo "Switching includes. . ."
			fi
			# Switch wp-admin with fresh folder
			if [ -d "$wp_admin_fresh" ]; then
				sudo mv "$current_path/wp-admin" "$current_path/wordpress-$wp_version/o-wp-admin"
				sudo mv $wp_admin_fresh "$current_path/wp-admin"
				sudo chown -R $current_user:$current_user "$current_path/wp-admin"
				echo "Switching admin. . ."
			fi
			
			echo "Removing leftovers..."
			cd $current_path && sudo sudo rm -r "wordpress-$wp_version" && cd /home

			# Clear cache
			if [ -d "$current_path/wp-content/cache" ]; then
				echo "Cleaning cache. . ."
				cd $current_path/wp-content && sudo sudo rm -r cache && mkdir cache && sudo chown -R $current_user:$current_user cache && cd /home
				sudo rm -rf "$current_path/wp-content/cache/*"
			fi
			if [ -d "$current_path/wp-content/supercache" ]; then
				echo "Cleaning cache. . ."
				cd $current_path/wp-content && sudo sudo rm -r supercache && mkdir supercache && sudo chown -R $current_user:$current_user supercache && cd /home
				sudo rm -rf "$current_path/wp-content/supercache/*"
			fi
		else
			echo "Unable to download / create wordpress-$wp_version.tar.gz" >> /home/wp_cores.log
		fi
		
		echo "fixing permissions. . ."
		find $current_path -type d -exec chmod 0755 {} \;
		find $current_path -type f -exec chmod 0644 {} \;

		echo "DONE! Moving to next one...."

	fi
done
