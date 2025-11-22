resource "aws_wafv2_api_key" "example" {
  scope         = "REGIONAL"
  token_domains = ["example.com"]
}

#RECURSOS API GATEWAY (Que es cognito?)
resource "aws_api_gateway_rest_api" "apibonita" {
  body = jsonencode({
    openapi = "3.0.1"
    info = {
      title   = "example"
      version = "1.0"
    }
    paths = {
      "/path1" = {
        get = {
          x-amazon-apigateway-integration = {
            httpMethod           = "GET"
            payloadFormatVersion = "1.0"
            type                 = "HTTP_PROXY"
            uri                  = "https://ip-ranges.amazonaws.com/ip-ranges.json"
          }
        }
      }
    }
  })

  name = "example"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_apigatewayv2_api" "apibonita2" {
  name          = "example-api"
  protocol_type = "HTTP"
}

resource "aws_apigateway_deployment" "apibonita3"{
    rest_api_id = aws_apigatewayv2_api.example.id
    trigger {
      redeployment = sha1(jsonencode(aws_apigatewayv2_api.example))
    }
     lifecycle {
    create_before_destroy = true
  }

resource "aws_api_gateway_stage" "apibonita4" {
  deployment_id = aws_api_gateway_deployment.example.id
  rest_api_id   = aws_api_gateway_rest_api.example.id
  stage_name    = "example"
}
endpoint_configuration {
    types = ["REGIONAL"]
  }
}
#PROPORCIONAR UN METODO API PARA MI RECURSO 
resource "aws_api_gateway_rest_api" "MyDemoAPI" {
  name        = "MyDemoAPI"
  description = "This is my API for demonstration purposes"
}

resource "aws_api_gateway_resource" "MyDemoResource" {
  rest_api_id = aws_api_gateway_rest_api.MyDemoAPI.id
  parent_id   = aws_api_gateway_rest_api.MyDemoAPI.root_resource_id
  path_part   = "mydemoresource"
}

resource "aws_api_gateway_method" "MyDemoMethod" {
  rest_api_id   = aws_api_gateway_rest_api.MyDemoAPI.id
  resource_id   = aws_api_gateway_resource.MyDemoResource.id
  http_method   = "GET"
  authorization = "NONE"
}