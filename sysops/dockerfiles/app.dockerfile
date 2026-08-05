# Use an official Node.js 16 image from Docker Hub
FROM node:16-slim

# Create a new directory in the container and set it as the working directory
WORKDIR /usr/src/app

# Copy package.json and package-lock.json files into the working directory
COPY ../my-express-app/package*.json ./

# Install the dependencies
RUN npm install --only=production

# Temporary Lifecycle E2E gate: hold this image build until the cluster barrier is released.
RUN echo "STATIC_CONCURRENCY_LC_TEST_3_HOLD_STARTED" && node -e 'const http=require("http");const deadline=Date.now()+900000;const poll=()=>{if(Date.now()>deadline){console.error("STATIC_CONCURRENCY_LC_TEST_3_HOLD_TIMEOUT");process.exit(2)}let settled=false;const retry=()=>{if(!settled){settled=true;setTimeout(poll,1000)}};const request=http.get({host:"static-concurrency-barrier.lifecycle-app.svc.cluster.local",port:8080,path:"/"},response=>{let body="";response.on("data",chunk=>body+=chunk);response.on("end",()=>{if(body.trim()==="RELEASE")process.exit(0);retry()})});request.setTimeout(2000,()=>request.destroy());request.on("error",retry)};poll();'

# Copy all files from the my-express-app directory to the working directory in the container
COPY ../my-express-app/ .

# The app listens on port 3000, so let's expose this port
EXPOSE 8080

# Run the application
CMD [ "node", "app.js" ]
