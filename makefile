IMAGE_NAME = aws-lambda

build-lambda:
	docker build -t $(IMAGE_NAME) ./code

remove-build:
	docker rmi $(IMAGE_NAME)

run-lambda:
	docker run --rm -p 9000:8080 $(IMAGE_NAME)

execute-lambda:
	curl -XPOST "http://localhost:9000/2015-03-31/functions/function/invocations" -d '{}'

login-ecr:
	aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 873843263579.dkr.ecr.us-east-2.amazonaws.com/demo-terraform