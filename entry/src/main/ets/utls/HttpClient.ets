import { http } from '@kit.NetworkKit';
import { Result } from '../model/Result';

const HOST = "http://172.27.127.11:8080/"

export async function request(url:string,method:http.RequestMethod = http.RequestMethod.GET,params?:object,header?:object):Promise<http.HttpResponse> {
  // 先检查一下当前的url中是否包含了HOST
  if (url.indexOf(HOST) == -1){
    url = HOST + url;
  }
  // 如果是get请求，并且携带参数，就需要将参数拼接到url后面
  if (method == http.RequestMethod.GET && params){
    let keys = Object.keys(params) // 取出params对象的所有属性名
    url += "?" + keys.map(key=>{
      let value = params[key] as object
      if (value){ // 该属性有值
        return key + "=" + value
      } else {
        return ""
      }
    }).join("&")
  }
  // 默认情况下如果不是get请求 那么请求参数都设置为json
  if (header){
    header = new Object()
  }
  if (method != http.RequestMethod.GET && header && !header['Content-Type']){
    header['Content-Type'] = "application/json;charset=utf-8"
  }
  // 创建请求客户端
  let httpClient = http.createHttp()
  let options:http.HttpRequestOptions = {
    method,
    extraData:params,
    header,
    readTimeout:10000,
    connectTimeout:10000
  }
  // 请求
  let response = await httpClient.request(url,options)
  // 关闭客户端
  httpClient.destroy()
  // 返回响应
  return response;
}

export async function get(url:string,params?:object,header?:object):Promise<http.HttpResponse>{
  return await request(url,http.RequestMethod.GET,params,header)
}

export async function post(url:string,params?:object,header?:object):Promise<http.HttpResponse>{
  return await request(url,http.RequestMethod.POST,params,header)
}

export async function getNormal<T>(url:string,params?:object,header?:object):Promise<Result<T>>{
  let response = await get(url,params,header)
  return new Promise<Result<T>>((resolve,reject)=>{
    if (response.responseCode == 200){
      let body = JSON.parse(response.result as string) as Result<T>
      resolve(body)
    } else {
      reject(response.result)
    }
  })
}

export async function postNormal<T>(url:string,params?:object,header?:object):Promise<Result<T>>{
  let response = await post(url,params,header)
  return new Promise<Result<T>>((resolve,reject)=>{
    if (response.responseCode == 200){
      let body = JSON.parse(response.result as string) as Result<T>
      resolve(body)
    } else {
      reject(response.result)
    }
  })
}