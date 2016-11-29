# T149963: Analyze WDQS traffic data to find parallel connection patterns

We would like to know whether there are WDQS clients that run a lot of queries on the service in parallel, and if so, how frequent this is, how many clients do this and to what measure. This would allow us to evaluate the impact of rate limiting on users. As many clients can be behind proxies, we would also like to know if it influences the calculation and what would be impact of rate limiting to such users.

We plan to use X-Client-IP header in decisions about rate limiting and would like to know if it makes sense and what would be the impact.

**Analyze WDQS traffic in order to answer the following questions:**

- [ ] How many IPs use parallel connections to the WDQS servers?
- [ ] How many parallel connections are typically used, how frequent is to use more than 3, what is the max, etc.?
- [ ] Out of the IPs that do the above, how many have the same/different user agents (hinting at one tool or proxy serving multiple clients)?
- [ ] In general, how many user agents per IP we have - do we have some IPs that have a lot of different agents (indicating a proxy), how much and how traffic from those IPs looks like - e.g. how many parallel requests, how often theres more than one, more than three?

By parallel connections we understand two connections from the same IP in which time intervals from request start to first byte sent to the response (time_firstbyte) intersect. Note that since we have more that one server, the requests may have been sent to separate servers, maybe we can correlate with logstash logs from wdqs servers to know which server it goes to. The ideal situation is if we have per-server data, but if that's not feasible, we can do with aggregated data.