-- The initial gateway default of 2 requests per minute is a single global
-- counter shared by every user, so normal scanning answered "rate_limited" and
-- legitimate links ended up unverified. Raise it; day and month caps still
-- protect the Web Risk quota.
update private.qr_gateway_config
set per_minute_limit = 20,
    updated_at = now()
where singleton = true
  and per_minute_limit < 20;
