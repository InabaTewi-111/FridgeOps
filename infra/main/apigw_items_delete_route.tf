# DELETE /items/{id} -> same Lambda integration as GET/POST

resource "aws_apigatewayv2_route" "items_delete" {
  api_id    = aws_apigatewayv2_api.items.id
  route_key = "DELETE /items/{id}"
  target    = "integrations/${aws_apigatewayv2_integration.items.id}"
}
