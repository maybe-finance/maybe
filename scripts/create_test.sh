autocannon -c 100 -d 30 -p 10 \
  -m POST \
  -H "Content-Type: application/json" \
  -b '{"email":"test@example.com","plan_id":"plan_xyz"}' \
  http://localhost:3000/subscriptions
