module Docker
  include ShellExecutor

  def stop(container_name)
    exec!("docker stop #{container_name}")
  end

  def start(container_name)
    exec!("docker start #{container_name}")
  end

  def nextcloud_maintenance_on(container_name)
    exec!("docker exec -u www-data -i #{container_name} php /var/www/html/occ maintenance:mode --on")
  end

  def nextcloud_maintenance_off(container_name)
    exec!("docker exec -u www-data -i #{container_name} php /var/www/html/occ maintenance:mode --off")
  end

end