namespace OOP_Practice;

public class Solution
{
    // 5.1 — Solution with prefix[] and suffix[] arrays
    //
    // Time Complexity: O(n)
    // Space Complexity: O(n) extra space
    //
    public int[] ProductExceptSelf(int[] nums)
    {
        int n = nums.Length;

        if (n == 0)
            return [];

        int[] prefix = new int[n];
        int[] suffix = new int[n];
        int[] answer = new int[n];
        
        prefix[0] = 1;
        for (int i = 1; i < n; i++)
            prefix[i] = prefix[i - 1] * nums[i - 1];
        
        suffix[n - 1] = 1;
        for (int i = n - 2; i >= 0; i--)
            suffix[i] = suffix[i + 1] * nums[i + 1];
        
        for (int i = 0; i < n; i++)
            answer[i] = prefix[i] * suffix[i];

        return answer;
    }

    // 5.2 — Follow-up: O(1) extra space
    //
    // Time Complexity: O(n)
    // Space Complexity: O(1) extra space
    //
    public int[] ProductExceptSelfOptimized(int[] nums)
    {
        int n = nums.Length;
        int[] answer = new int[n];


        int prefix = 1;
        for (int i = 0; i < n; i++)
        {
            answer[i] = prefix;
            prefix *= nums[i];
        }
        
        int suffix = 1;
        for (int i = n - 1; i >= 0; i--)
        {
            answer[i] *= suffix;
            suffix *= nums[i];
        }

        return answer;
    }
}