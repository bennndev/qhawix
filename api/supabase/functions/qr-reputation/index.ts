import { handleRequest } from "./gateway.ts";

Deno.serve((request: Request) => handleRequest(request));
