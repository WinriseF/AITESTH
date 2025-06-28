import http from '@ohos.net.http';
import { BusinessError } from '@kit.BasicServicesKit';
import util from '@ohos.util';

const API_BASE_URL = 'http://172.27.20.121:8080';

// 定义通用的API响应结构，方便在整个应用中复用
export interface ApiResponse<T> {
  code: number;
  message: string;
  data: T;
}

/**
 * @param msg 用户的聊天内容字符串
 * @returns 返回一个 Promise，其值为AI的完整回复字符串
 */
export function simpleChat(msg: string): Promise<string> {
  // 对消息进行URL编码，以防包含特殊字符（如&, ?, 空格等）
  const encodedMsg = encodeURIComponent(msg);
  const path = `/chat/chat?msg=${encodedMsg}`;
  const url = `${API_BASE_URL}${path}`;

  let httpRequest = http.createHttp();

  return httpRequest.request(url, {
    method: http.RequestMethod.GET, // 这是一个GET请求
    connectTimeout: 30000, // 30秒超时
    readTimeout: 30000,
  }).then(response => {
    // 销毁请求，释放资源
    httpRequest.destroy();

    if (response.responseCode >= 200 && response.responseCode < 300) {
      // 请求成功，直接返回结果字符串
      return response.result as string;
    } else {
      // HTTP层面失败，抛出错误
      throw new Error(`HTTP Error: ${response.responseCode}`);
    }
  }).catch((err: BusinessError | Error) => {
    // 创建一个新的、类型确定的 Error 对象
    throw new Error(err.message || '网络请求发生未知错误');
  }).finally(() => {
    httpRequest.destroy();
  });
}

/**
 * 封装一个通用的请求函数，作为所有请求的核心
 * @param path API的相对路径, e.g., "/question/asyncGenerateQuestion"
 * @param options http请求的配置
 * @returns 返回一个 Promise，其值为解析后的业务数据
 */
async function request<T>(path: string, options: http.HttpRequestOptions): Promise<ApiResponse<T>> {
  const url = `${API_BASE_URL}${path}`;
  let httpRequest = http.createHttp();

  try {
    console.log(`[HttpClient] Requesting: ${options.method} ${url}`);
    if (options.extraData) {
      const body_snippet = (options.extraData as string).substring(0, 200);
      console.log(`[HttpClient] Body: ${body_snippet}...`);
    }

    const response = await httpRequest.request(url, options);

    console.log(`[HttpClient] Response Code: ${response.responseCode}`);
    console.log(`[HttpClient] Response Body: ${response.result}`);

    if (response.responseCode >= 200 && response.responseCode < 300) {
      // HTTP状态码成功
      const resultJson = JSON.parse(response.result as string) as ApiResponse<T>;
      // 检查后端返回的业务状态码
      if (resultJson.code === 200) {
        return resultJson;
      } else {
        // 业务处理失败，抛出一个包含后端错误信息的Error
        throw new Error(resultJson.message || '后端业务处理失败');
      }
    } else {
      // HTTP层面失败
      throw new Error(`HTTP 错误，状态码: ${response.responseCode}`);
    }
  } catch (err) {
    const error = err as BusinessError | Error;
    console.error(`[HttpClient] 请求 ${url} 发生严重错误: ${JSON.stringify(error)}`);
    throw new Error(error.message || '发生未知网络错误，请检查网络连接或服务器状态');
  } finally {
    httpRequest.destroy();
  }
}

/**
 * 封装通用的POST请求方法
 * @param path API的相对路径
 * @param data 要发送的JS对象，会自动转换为JSON字符串
 * @returns
 */
export function post<T>(path: string, data: object): Promise<ApiResponse<T>> {
  return request<T>(path, {
    method: http.RequestMethod.POST,
    header: {
      'Content-Type': 'application/json'
    },
    extraData: JSON.stringify(data),
    connectTimeout: 15000, // 15秒连接超时
    readTimeout: 15000,    // 15秒读取超时
  });
}

/**
 * 封装通用的GET请求方法
 * @param path API的相对路径
 * @returns
 */
export function get<T>(path: string): Promise<ApiResponse<T>> {
  return request<T>(path, {
    method: http.RequestMethod.GET,
    connectTimeout: 15000,
    readTimeout: 15000,
  });
}
