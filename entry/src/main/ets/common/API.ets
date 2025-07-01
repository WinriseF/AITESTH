import { QuestionModel } from '../model/QuestionModel';
import { AppDataSource } from './AppDataSource';
import HttpClient, { ApiResponse } from '../utls/HttpClient';

export interface GenerateQuestionDto {
  question: string;
  questionNum: number;
  difficulty: string;
  generateId: string;
  category?: string;
}

export interface QuizSet {
  id: number;
  generateId: string;
  title: string;
  category: string;
  totalQuestions: number;
  createdAt: string; // 后端的LocalDateTime会序列化为ISO格式的字符串
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
  return HttpClient.post<string>('/question/asyncGenerateQuestion', params);
}

export function createQuizSet(params: GenerateQuestionDto): Promise<ApiResponse<QuizSet>> {
  return HttpClient.post<QuizSet>('/quiz-bank/sets', params);
}

export function getQuizSets(): Promise<ApiResponse<QuizSet[]>> {
  return HttpClient.get<QuizSet[]>('/quiz-bank/sets');
}
/**
 * 根据批次ID查询已生成的题目列表
 * @param generateId 批次ID
 * @returns 一个Promise，其值为包含题目数组的ApiResponse
 */
export function getQuestionsByBatchId(generateId: string): Promise<ApiResponse<QuestionModel[]>> {
  return HttpClient.get<QuestionModel[]>(`/question/question/${generateId}`);
}

export function simpleChat(message: string): Promise<string> {
  const requestBody: ChatRequestBody = { msg: message };
  return HttpClient.postAndGetRawResponse('/chat/simpleChat', requestBody);
}

export interface UserLoginDto {
  username?: string;
  password?: string;
}

export interface UserRegistrationDto {
  username?: string;
  password?: string;
  email?: string;
}

// --- 新增的 API 函数 ---
export async function loginUser(params: UserLoginDto): Promise<ApiResponse<string>> {
  return HttpClient.post<string>('/user/login', params);
}

export async function registerUser(params: UserRegistrationDto): Promise<ApiResponse<string>> {
  return HttpClient.post<string>('/user/register', params);
}