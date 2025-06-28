import { get, post, ApiResponse, postSimple } from '../utls/HttpClient';
import { QuestionModel } from '../model/QuestionModel';

export interface GenerateQuestionDto {
  question: string;
  questionNum: number;
  difficulty: string;
  generateId: string;
}

interface ChatRequestBody {
  msg: string;
}

/**
 * 提交一个题目生成的子任务
 * @param params 包含题目主题、数量、难度和批次ID的参数对象
 * @returns 一个Promise，其值为包含生成ID字符串的ApiResponse
 */
export function submitGenerationTask(params: GenerateQuestionDto): Promise<ApiResponse<string>> {
  return post<string>('/question/asyncGenerateQuestion', params);
}

/**
 * 根据批次ID查询已生成的题目列表
 * @param generateId 批次ID
 * @returns 一个Promise，其值为包含题目数组的ApiResponse
 */
export function getQuestionsByBatchId(generateId: string): Promise<ApiResponse<QuestionModel[]>> {
  return get<QuestionModel[]>(`/question/question/${generateId}`);
}

export function simpleChat(message: string): Promise<string> {
  const requestBody: ChatRequestBody = { msg: message };
  return postSimple('/chat/simpleChat', requestBody);
}