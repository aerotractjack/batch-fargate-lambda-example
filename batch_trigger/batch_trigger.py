import boto3
import time

JOB_DEFN = "pix4dengine-batch-aerotract-batch-job-defn"
JOB_Q = "pix4dengine-batch-aerotract-batch-job-queue"

class BatchRunner:
    ''' Class to manage running jobs in our Batch environment '''

    def __init__(self, job=JOB_DEFN, q=JOB_Q):
        ''' initialize an instance of this class 
        @param job (str): name of AWS Batch job definition
        @param q (str):   name of AWS Batch job queue '''
        self.job_defn = job
        self.job_q = q

    def get_client(self):
        ''' get an AWS Batch client 
        @returns: boto3.client '''
        return boto3.client('batch', region_name="us-west-1")
    
    def submit(self, name="", params={}):
        ''' submit a job to AWS Batch
        @param name (str): name of this AWS Batch job to execute
        @param params (dict[str]str): keyword arguments to pass to Batch job 
        @returns (dict[str]str): JSON response body '''
        cli = self.get_client()
        if name is None or name == "":
            tstr = int(time.time())
            name = f"job-{tstr}"
        envoverride = [{"name": k, "value": v} for k,v in params.items()]
        resp = cli.submit_job(
            jobName=name,
            jobQueue=self.job_q,
            jobDefinition=self.job_defn,
            containerOverrides={
                'environment': envoverride
            }
        )
        return resp
    
    def check_status(self, submit_resp):
        ''' check the status of an AWS Batch job
        @param submit_resp (dict[str]str) JSON response from AWS Batch job submission 
        @returns (dict[str]str): ID and status of job in JSON format'''
        cli = self.get_client()
        job_name = submit_resp["jobName"]
        jobi = submit_resp["jobId"]
        status_check = cli.describe_jobs(jobs=[jobi])
        status = status_check["jobs"][0]["status"]
        out = {"jobName": job_name, "jobId": jobi, "status": status}
        return out

def test(event, context):
    br = BatchRunner()
    out = br.submit(name="MYJOB-fromlambda", params={"p1": "v1", "p2": "v2"})
    return out

if __name__ == "__main__":
    test()