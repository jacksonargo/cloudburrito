require_relative '../cloudburrito'

Patron.each do |patron|
  patron.active = patron.is_active
  patron.active_at = Time.now
  patron.save
end

Package.each do |package|
  package.failed_at = package.updated_at if package.failed
  package.en_route_at = package.updated_at if package.en_route
  if package.received
    package.assigned_at = package.updated_at
    package.received_at = package.delivery_time
    package.en_route_at = package.updated_at
    package.assigned = true
    package.en_route = true
  end
end
